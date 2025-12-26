"""
========================================
Track 1: Yahoo Finance API 뉴스 링크 수집
========================================

목적:
- NASDAQ 종목의 뉴스 링크 수집
- Yahoo Finance Search API 사용 (v1)
- 종목 선택 및 개수 설정 가능
- 중복 제거 (URL 기준)

사용법:
- 전체 종목: python news_api_collector.py
- 전체 종목 + 개수: python news_api_collector.py --count 5
- 특정 종목: python news_api_collector.py --symbols AAPL,MSFT,GOOGL
- 특정 종목 + 개수: python news_api_collector.py --symbols AAPL,MSFT --count 3

출력:
- python/output/news_links.json
"""

import requests
import json
from datetime import datetime
import pytz
from pathlib import Path
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import pandas as pd
import argparse
import time

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

kst = pytz.timezone('Asia/Seoul')


class NewsConfig:
    """설정"""
    DEFAULT_NEWS_PER_SYMBOL = 5  # 기본값: 종목당 5개
    MAX_NEWS_PER_SYMBOL = 10     # 최대: 종목당 10개
    MAX_WORKERS = 10             # 병렬 처리 개수
    RETRY_COUNT = 2              # 재시도 횟수
    RETRY_DELAY = 1              # 재시도 대기 시간 (초)
    REQUEST_DELAY = 0.1          # 요청 간 딜레이 (초)
    OUTPUT_DIR = 'python/output'
    OUTPUT_FILE = 'news_links.json'
    
    # Yahoo Finance Search API
    API_URL = "https://query1.finance.yahoo.com/v1/finance/search"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }


def load_symbols_from_csv():
    """CSV에서 101개 종목 로드"""
    try:
        csv_file = 'python/nasdaq100_tickers.csv'
        
        if not Path(csv_file).exists():
            csv_file = 'nasdaq100_tickers.csv'
        
        df = pd.read_csv(csv_file)
        symbols = df['symbol'].str.strip().str.upper().tolist()
        
        logger.info(f"📂 Loaded {len(symbols)} symbols from CSV")
        return symbols
        
    except Exception as e:
        logger.error(f"❌ Failed to load CSV: {e}")
        raise


def fetch_news_for_symbol(symbol, max_news, retry_count=NewsConfig.RETRY_COUNT):
    """
    Yahoo Finance Search API로 뉴스 수집
    
    Returns:
        list: [{'symbol', 'title', 'url', 'summary', 'publisher', 'published_at', 'thumbnail_url'}]
    """
    for attempt in range(retry_count + 1):
        try:
            url = f"{NewsConfig.API_URL}?q={symbol}&newsCount={max_news}"
            
            response = requests.get(
                url, 
                headers=NewsConfig.HEADERS, 
                timeout=10
            )
            
            if response.status_code == 429:
                # Rate limit - 대기 후 재시도
                if attempt < retry_count:
                    logger.warning(f"  [RETRY] {symbol}: Rate limited, waiting...")
                    time.sleep(NewsConfig.RETRY_DELAY * 2)
                    continue
                else:
                    logger.error(f"  [ERROR] {symbol}: Rate limited after {retry_count} retries")
                    return []
            
            if response.status_code != 200:
                logger.error(f"  [ERROR] {symbol}: HTTP {response.status_code}")
                return []
            
            data = response.json()
            news_list = data.get('news', [])
            
            if not news_list:
                logger.debug(f"  [SKIP] {symbol}: No news")
                return []
            
            processed_news = []
            
            for article in news_list[:max_news]:
                try:
                    # 발행 시간 (Unix timestamp → KST)
                    publish_timestamp = article.get('providerPublishTime', 0)
                    if publish_timestamp:
                        dt = datetime.fromtimestamp(publish_timestamp, tz=pytz.UTC)
                        dt_kst = dt.astimezone(kst)
                        published_at = dt_kst.strftime('%Y-%m-%d %H:%M:%S')
                    else:
                        published_at = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
                    
                    # 썸네일 URL
                    thumbnail_url = None
                    thumbnail = article.get('thumbnail', {})
                    if thumbnail and 'resolutions' in thumbnail:
                        resolutions = thumbnail['resolutions']
                        if resolutions:
                            # 140x140 또는 첫 번째 이미지
                            for res in resolutions:
                                if res.get('tag') == '140x140':
                                    thumbnail_url = res.get('url')
                                    break
                            if not thumbnail_url:
                                thumbnail_url = resolutions[0].get('url')
                    
                    news_item = {
                        'symbol': symbol,
                        'title': article.get('title', 'No Title'),
                        'url': article.get('link', ''),
                        'summary': '',  # Search API는 summary 미제공
                        'publisher': article.get('publisher', 'Unknown'),
                        'published_at': published_at,
                        'thumbnail_url': thumbnail_url
                    }
                    
                    if news_item['url']:
                        processed_news.append(news_item)
                    
                except Exception as e:
                    logger.debug(f"  [WARN] {symbol}: Failed to process article: {e}")
                    continue
            
            if processed_news:
                logger.info(f"  [OK] {symbol}: {len(processed_news)} news")
            
            return processed_news
            
        except requests.exceptions.Timeout:
            if attempt < retry_count:
                logger.warning(f"  [RETRY] {symbol}: Timeout, retrying ({attempt + 1}/{retry_count})...")
                time.sleep(NewsConfig.RETRY_DELAY)
            else:
                logger.error(f"  [ERROR] {symbol}: Timeout after {retry_count} retries")
                return []
                
        except Exception as e:
            if attempt < retry_count:
                logger.warning(f"  [RETRY] {symbol}: {e}, retrying ({attempt + 1}/{retry_count})...")
                time.sleep(NewsConfig.RETRY_DELAY)
            else:
                logger.error(f"  [ERROR] {symbol}: {e}")
                return []
    
    return []


def collect_all_news_parallel(symbols, max_workers, max_news):
    """병렬로 뉴스 링크 수집"""
    logger.info("="*60)
    logger.info(f"[PARALLEL] Starting with {max_workers} workers")
    logger.info(f"[CONFIG] Symbols: {len(symbols)}, News per symbol: {max_news}")
    logger.info("="*60)
    
    all_news = []
    success_count = 0
    error_count = 0
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_symbol = {
            executor.submit(fetch_news_for_symbol, symbol, max_news): symbol 
            for symbol in symbols
        }
        
        for future in as_completed(future_to_symbol):
            symbol = future_to_symbol[future]
            try:
                news_list = future.result()
                if news_list:
                    all_news.extend(news_list)
                    success_count += 1
                else:
                    error_count += 1
            except Exception as e:
                logger.error(f"  [ERROR] {symbol}: {e}")
                error_count += 1
            
            # Rate limit 방지를 위한 딜레이
            time.sleep(NewsConfig.REQUEST_DELAY)
    
    logger.info("="*60)
    logger.info(f"[STATS] Success: {success_count}, Errors: {error_count}")
    logger.info(f"[STATS] Total news: {len(all_news)}")
    logger.info("="*60)
    
    return all_news


def remove_duplicates(news_list):
    """URL 기준으로 중복 제거"""
    seen_urls = set()
    unique_news = []
    
    for news in news_list:
        url = news['url']
        if url not in seen_urls:
            seen_urls.add(url)
            unique_news.append(news)
    
    removed = len(news_list) - len(unique_news)
    logger.info(f"[DEDUP] {len(news_list)} → {len(unique_news)} (removed {removed} duplicates)")
    
    return unique_news


def save_news_links_to_json(news_list, output_dir, output_file):
    """뉴스 링크를 JSON 파일로 저장"""
    try:
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        output_path = Path(output_dir) / output_file
        
        output_data = {
            'timestamp': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'total_news': len(news_list),
            'data': news_list
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        logger.info("="*60)
        logger.info(f"[SAVE] News links saved: {output_path}")
        logger.info(f"[STATS] Total news: {len(news_list)}")
        logger.info("="*60)
        
        return str(output_path)
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to save news links: {e}")
        raise


def parse_arguments():
    """명령줄 인자 파싱"""
    parser = argparse.ArgumentParser(description='Yahoo Finance 뉴스 수집기')
    
    parser.add_argument(
        '--symbols',
        type=str,
        default='',
        help='수집할 종목 (쉼표 구분). 비워두면 전체 종목'
    )
    
    parser.add_argument(
        '--count',
        type=int,
        default=NewsConfig.DEFAULT_NEWS_PER_SYMBOL,
        help=f'종목당 뉴스 개수 (기본: {NewsConfig.DEFAULT_NEWS_PER_SYMBOL}, 최대: {NewsConfig.MAX_NEWS_PER_SYMBOL})'
    )
    
    return parser.parse_args()


def main():
    """메인 함수"""
    # 인자 파싱
    args = parse_arguments()
    
    # 종목 결정
    if args.symbols:
        symbols = [s.strip().upper() for s in args.symbols.split(',') if s.strip()]
        logger.info(f"📌 특정 종목 모드: {symbols}")
    else:
        symbols = load_symbols_from_csv()
        logger.info(f"📌 전체 종목 모드: {len(symbols)}개")
    
    # 개수 제한
    max_news = min(args.count, NewsConfig.MAX_NEWS_PER_SYMBOL)
    max_news = max(max_news, 1)  # 최소 1개
    
    logger.info("="*60)
    logger.info("Track 1: News API Collector Started")
    logger.info("="*60)
    logger.info(f"Configuration:")
    logger.info(f"  - Symbols: {len(symbols)}")
    logger.info(f"  - News per symbol: {max_news}")
    logger.info(f"  - Max workers: {NewsConfig.MAX_WORKERS}")
    logger.info(f"  - API: Yahoo Finance Search API (v1)")
    logger.info("="*60)
    
    try:
        # 1. 뉴스 링크 수집 (병렬)
        news_list = collect_all_news_parallel(
            symbols, 
            max_workers=NewsConfig.MAX_WORKERS,
            max_news=max_news
        )
        
        # 2. 중복 제거
        unique_news = remove_duplicates(news_list)
        
        # 3. JSON 저장
        save_news_links_to_json(
            unique_news,
            output_dir=NewsConfig.OUTPUT_DIR,
            output_file=NewsConfig.OUTPUT_FILE
        )
        
        logger.info("="*60)
        logger.info("✅ Track 1 Completed Successfully")
        logger.info("="*60)
        
    except Exception as e:
        logger.error(f"❌ Track 1 failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
