"""
========================================
Track 1: Yahoo Finance API 뉴스 링크 수집
========================================

목적:
- 101개 NASDAQ 종목의 뉴스 링크 수집
- 빠른 API 호출 (병렬 처리)
- 중복 제거 (URL 기준)

출력:
- python/output/news_links.json
"""

import yfinance as yf
import json
from datetime import datetime
import pytz
from pathlib import Path
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import pandas as pd

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

kst = pytz.timezone('Asia/Seoul')


class NewsConfig:
    """설정"""
    MAX_NEWS_PER_SYMBOL = 10  # 종목당 최대 뉴스 개수
    MAX_WORKERS = 20           # 병렬 처리 개수
    OUTPUT_DIR = 'python/output'
    OUTPUT_FILE = 'news_links.json'


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


def fetch_news_links_for_symbol(symbol, max_news):
    """
    특정 종목의 뉴스 링크 수집 (API만 사용)
    
    Returns:
        list: [{'symbol', 'title', 'url', 'summary', 'publisher', 'published_at', 'thumbnail_url'}]
    """
    try:
        ticker = yf.Ticker(symbol)
        news = ticker.news
        
        if not news:
            logger.debug(f"  [SKIP] {symbol}: No news")
            return []
        
        news_list = []
        
        for article in news[:max_news]:
            try:
                content = article.get('content', {})
                
                if not content:
                    continue
                
                # URL 확인
                click_through = content.get('clickThroughUrl', {})
                url = click_through.get('url', '')
                
                if not url:
                    continue
                
                # 발행 시간 처리 (ISO 형식)
                pub_date = content.get('pubDate', '')
                
                if pub_date:
                    try:
                        # ISO 형식 파싱 (2025-12-22T10:25:44.000Z)
                        dt = datetime.fromisoformat(pub_date.replace('Z', '+00:00'))
                        dt_kst = dt.astimezone(kst)
                        published_at = dt_kst.strftime('%Y-%m-%d %H:%M:%S')
                    except Exception as e:
                        logger.debug(f"  [WARN] {symbol}: Date parsing failed: {e}")
                        published_at = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
                else:
                    published_at = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
                
                # 썸네일
                thumbnail_url = None
                thumbnail = content.get('thumbnail', {})
                if thumbnail and 'resolutions' in thumbnail and thumbnail['resolutions']:
                    for resolution in thumbnail['resolutions']:
                        if resolution.get('tag') == '170x128':
                            thumbnail_url = resolution.get('url')
                            break
                    if not thumbnail_url:
                        thumbnail_url = thumbnail['resolutions'][0].get('url')
                
                provider = content.get('provider', {})
                
                news_item = {
                    'symbol': symbol,
                    'title': content.get('title', 'No Title'),
                    'url': url,
                    'summary': content.get('summary', ''),
                    'publisher': provider.get('displayName', 'Unknown'),
                    'published_at': published_at,
                    'thumbnail_url': thumbnail_url
                }
                
                news_list.append(news_item)
                
            except Exception as e:
                logger.debug(f"  [ERROR] {symbol}: Failed to process article: {e}")
                continue
        
        if news_list:
            logger.info(f"  [OK] {symbol}: {len(news_list)} news")
        
        return news_list
        
    except Exception as e:
        logger.error(f"  [ERROR] {symbol}: {e}")
        return []


def collect_all_news_links_parallel(symbols, max_workers, max_news):
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
            executor.submit(fetch_news_links_for_symbol, symbol, max_news): symbol 
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
    
    logger.info(f"[DEDUP] {len(news_list)} → {len(unique_news)} (removed {len(news_list) - len(unique_news)} duplicates)")
    
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


def main():
    """메인 함수"""
    logger.info("="*60)
    logger.info("Track 1: News API Collector Started")
    logger.info("="*60)
    logger.info(f"Configuration:")
    logger.info(f"  - Max news per symbol: {NewsConfig.MAX_NEWS_PER_SYMBOL}")
    logger.info(f"  - Max workers: {NewsConfig.MAX_WORKERS}")
    logger.info("="*60)
    
    try:
        # 1. 종목 로드
        symbols = load_symbols_from_csv()
        
        # 2. 뉴스 링크 수집 (병렬)
        news_list = collect_all_news_links_parallel(
            symbols, 
            max_workers=NewsConfig.MAX_WORKERS,
            max_news=NewsConfig.MAX_NEWS_PER_SYMBOL
        )
        
        # 3. 중복 제거
        unique_news = remove_duplicates(news_list)
        
        # 4. JSON 저장
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