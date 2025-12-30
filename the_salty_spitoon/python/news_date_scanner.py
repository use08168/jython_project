"""
================================================================================
News Date Scanner
================================================================================
모든 종목의 뉴스 URL을 수집하고 날짜별로 그룹화하여 JSON으로 저장

사용법:
  python news_date_scanner.py

출력:
  python/output/scanned_news.json

@author The Salty Spitoon Team
@since 2025-12-30
================================================================================
"""

import sys
import os
import io

# Windows console UTF-8
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

os.environ['PYTHONUNBUFFERED'] = '1'

import requests
import json
import time
import logging
from datetime import datetime
from pathlib import Path
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

import pytz
import pandas as pd

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(stream=sys.stdout)]
)
logger = logging.getLogger(__name__)

# Timezone
kst = pytz.timezone('Asia/Seoul')

# Paths
SCRIPT_DIR = Path(__file__).parent.absolute()
OUTPUT_DIR = SCRIPT_DIR / 'output'
OUTPUT_FILE = OUTPUT_DIR / 'scanned_news.json'
CSV_FILE = SCRIPT_DIR / 'nasdaq100_tickers.csv'


class Config:
    """Configuration"""
    API_URL = "https://query1.finance.yahoo.com/v1/finance/search"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    NEWS_PER_SYMBOL = 10  # Yahoo API max
    MAX_WORKERS = 10
    REQUEST_DELAY = 0.1


def load_symbols():
    """Load symbols from CSV"""
    try:
        if not CSV_FILE.exists():
            raise FileNotFoundError(f"CSV not found: {CSV_FILE}")
        
        df = pd.read_csv(CSV_FILE)
        symbols = [s.strip() for s in df['symbol'].tolist() if not s.startswith('^')]
        
        logger.info(f"[CSV] Loaded {len(symbols)} symbols")
        return symbols
    except Exception as e:
        logger.error(f"[ERROR] CSV load failed: {e}")
        raise


def fetch_news_for_symbol(symbol):
    """Fetch news URLs for a symbol"""
    try:
        url = f"{Config.API_URL}?q={symbol}&newsCount={Config.NEWS_PER_SYMBOL}"
        response = requests.get(url, headers=Config.HEADERS, timeout=10)
        
        if response.status_code == 429:
            time.sleep(2)
            return []
        
        if response.status_code != 200:
            return []
        
        data = response.json()
        news_list = data.get('news', [])
        
        results = []
        for article in news_list:
            pub_time = article.get('providerPublishTime', 0)
            if not pub_time:
                continue
            
            # Convert to KST
            dt_utc = datetime.fromtimestamp(pub_time, tz=pytz.UTC)
            dt_kst = dt_utc.astimezone(kst)
            
            # Thumbnail
            thumbnail_url = None
            thumbnail = article.get('thumbnail', {})
            if thumbnail and 'resolutions' in thumbnail:
                resolutions = thumbnail['resolutions']
                if resolutions:
                    for res in resolutions:
                        if res.get('tag') == '140x140':
                            thumbnail_url = res.get('url')
                            break
                    if not thumbnail_url:
                        thumbnail_url = resolutions[0].get('url')
            
            results.append({
                'symbol': symbol,
                'title': article.get('title', 'No Title'),
                'url': article.get('link', ''),
                'publisher': article.get('publisher', 'Unknown'),
                'published_at': dt_kst.strftime('%Y-%m-%d %H:%M:%S'),
                'date': dt_kst.strftime('%Y-%m-%d'),  # For grouping
                'thumbnail_url': thumbnail_url
            })
        
        return results
        
    except Exception as e:
        return []


def scan_all_news(symbols):
    """Scan all symbols and collect news URLs"""
    logger.info("=" * 60)
    logger.info("[SCAN] Starting news URL scan")
    logger.info(f"[CONFIG] Symbols: {len(symbols)}, News per symbol: {Config.NEWS_PER_SYMBOL}")
    logger.info("=" * 60)
    
    all_news = []
    completed = 0
    
    with ThreadPoolExecutor(max_workers=Config.MAX_WORKERS) as executor:
        future_to_symbol = {
            executor.submit(fetch_news_for_symbol, symbol): symbol 
            for symbol in symbols
        }
        
        for future in as_completed(future_to_symbol):
            symbol = future_to_symbol[future]
            try:
                news_list = future.result()
                if news_list:
                    all_news.extend(news_list)
            except Exception as e:
                pass
            
            completed += 1
            if completed % 20 == 0:
                print(f"PROGRESS:{completed}/{len(symbols)}", flush=True)
            
            time.sleep(Config.REQUEST_DELAY)
    
    # Remove duplicates by URL
    seen_urls = set()
    unique_news = []
    for news in all_news:
        if news['url'] and news['url'] not in seen_urls:
            seen_urls.add(news['url'])
            unique_news.append(news)
    
    logger.info(f"[RESULT] Collected {len(unique_news)} unique news URLs")
    
    return unique_news


def group_by_date(news_list):
    """Group news by date"""
    grouped = defaultdict(list)
    
    for news in news_list:
        date = news.get('date', 'unknown')
        grouped[date].append(news)
    
    # Sort dates descending
    sorted_dates = sorted(grouped.keys(), reverse=True)
    
    result = {}
    for date in sorted_dates:
        result[date] = grouped[date]
    
    return result


def save_to_json(grouped_news, total_count):
    """Save scanned news to JSON"""
    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        
        # Calculate date summary
        date_summary = {}
        for date, news_list in grouped_news.items():
            date_summary[date] = {
                'count': len(news_list),
                'symbols': list(set(n['symbol'] for n in news_list))
            }
        
        output_data = {
            'scan_timestamp': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'total_news': total_count,
            'date_count': len(grouped_news),
            'date_summary': date_summary,
            'news_by_date': grouped_news
        }
        
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"[SAVED] {OUTPUT_FILE}")
        
        # Print summary
        logger.info("=" * 60)
        logger.info("[DATE SUMMARY]")
        for date in sorted(grouped_news.keys(), reverse=True):
            count = len(grouped_news[date])
            logger.info(f"  {date}: {count} news")
        logger.info("=" * 60)
        
        return str(OUTPUT_FILE)
        
    except Exception as e:
        logger.error(f"[ERROR] Save failed: {e}")
        raise


def main():
    """Main function"""
    print("[START] News Date Scanner", flush=True)
    
    try:
        # Load symbols
        symbols = load_symbols()
        
        # Scan all news
        all_news = scan_all_news(symbols)
        
        if not all_news:
            print("[COMPLETE] No news found", flush=True)
            return
        
        # Group by date
        grouped_news = group_by_date(all_news)
        
        # Save to JSON
        save_to_json(grouped_news, len(all_news))
        
        print(f"[COMPLETE] Scanned {len(all_news)} news across {len(grouped_news)} dates", flush=True)
        
    except Exception as e:
        print(f"[FATAL] {str(e)}", flush=True)
        logger.error(f"[FATAL] {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
