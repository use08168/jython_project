"""
========================================
News Collector (Integrated Version)
========================================

Features:
1. Yahoo Finance API - Collect news URLs
2. Selenium - Crawl article content (skip external)
3. OpenAI API - Translate to Korean + Markdown
4. gzip + Base64 encoding
5. Save JSON -> Spring Boot saves to MySQL

Usage:
- All symbols: python news_collector.py
- Specific: python news_collector.py --symbols AAPL,MSFT
- Count: python news_collector.py --count 5

Output:
- python/output/news_details.json

@author The Salty Spitoon Team
@since 2025-12-30
"""

import sys
import os
import io

# Windows console UTF-8 (prevent emoji errors)
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

os.environ['PYTHONUNBUFFERED'] = '1'

import requests
import json
import time
import gzip
import base64
import argparse
import logging
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import pytz
import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from dotenv import load_dotenv
from openai import OpenAI

# Logging setup (English only)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(stream=sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Timezone
kst = pytz.timezone('Asia/Seoul')

# Path setup
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent
OUTPUT_DIR = SCRIPT_DIR / 'output'
ENV_FILE = PROJECT_ROOT / '.env'

# Load .env
load_dotenv(ENV_FILE)


# ========================================
# Config
# ========================================

class Config:
    """Configuration"""
    # Yahoo Finance API
    API_URL = "https://query1.finance.yahoo.com/v1/finance/search"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    # Collection settings
    DEFAULT_NEWS_PER_SYMBOL = 10
    MAX_NEWS_PER_SYMBOL = 10
    MAX_WORKERS = 10
    REQUEST_DELAY = 0.1
    CRAWL_DELAY = 2
    
    # Selenium
    HEADLESS = True
    PAGE_LOAD_TIMEOUT = 10
    
    # OpenAI
    OPENAI_MODEL = "gpt-4o-mini"
    
    # Output
    OUTPUT_FILE = 'news_details.json'


# ========================================
# OpenAI Client
# ========================================

def get_openai_client():
    """Create OpenAI client"""
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        raise ValueError("OPENAI_API_KEY not found in .env file")
    if api_key.startswith('your_') or api_key == 'sk-your-api-key-here':
        raise ValueError("OPENAI_API_KEY is placeholder. Please set real API key in .env")
    return OpenAI(api_key=api_key)


# ========================================
# 1. Yahoo Finance API - News URL Collection
# ========================================

def load_symbols_from_csv():
    """Load symbols from CSV"""
    try:
        csv_file = SCRIPT_DIR / 'nasdaq100_tickers.csv'
        
        if not csv_file.exists():
            raise FileNotFoundError(f"CSV file not found: {csv_file}")
        
        df = pd.read_csv(csv_file)
        # Exclude index symbols starting with ^
        symbols = [s.strip() for s in df['symbol'].tolist() if not s.startswith('^')]
        
        logger.info(f"[CSV] Loaded {len(symbols)} symbols")
        return symbols
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to load CSV: {e}")
        raise


def fetch_news_for_symbol(symbol, max_news):
    """Fetch news from Yahoo Finance API"""
    try:
        url = f"{Config.API_URL}?q={symbol}&newsCount={max_news}"
        
        response = requests.get(url, headers=Config.HEADERS, timeout=10)
        
        if response.status_code == 429:
            logger.warning(f"  [RATE LIMIT] {symbol}")
            time.sleep(2)
            return []
        
        if response.status_code != 200:
            logger.error(f"  [ERROR] {symbol}: HTTP {response.status_code}")
            return []
        
        data = response.json()
        news_list = data.get('news', [])
        
        if not news_list:
            return []
        
        processed_news = []
        
        for article in news_list[:max_news]:
            try:
                # Publish time
                publish_timestamp = article.get('providerPublishTime', 0)
                if publish_timestamp:
                    dt = datetime.fromtimestamp(publish_timestamp, tz=pytz.UTC)
                    dt_kst = dt.astimezone(kst)
                    published_at = dt_kst.strftime('%Y-%m-%d %H:%M:%S')
                else:
                    published_at = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
                
                # Thumbnail URL
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
                
                news_item = {
                    'symbol': symbol,
                    'title': article.get('title', 'No Title'),
                    'url': article.get('link', ''),
                    'publisher': article.get('publisher', 'Unknown'),
                    'published_at': published_at,
                    'thumbnail_url': thumbnail_url
                }
                
                if news_item['url']:
                    processed_news.append(news_item)
                
            except Exception as e:
                continue
        
        if processed_news:
            logger.info(f"  [OK] {symbol}: {len(processed_news)} news")
        
        return processed_news
        
    except Exception as e:
        logger.error(f"  [ERROR] {symbol}: {e}")
        return []


def collect_news_urls_parallel(symbols, max_news):
    """Collect news URLs in parallel"""
    logger.info("=" * 60)
    logger.info("[STEP 1] Yahoo Finance API - Collecting news URLs")
    logger.info(f"[CONFIG] Symbols: {len(symbols)}, News per symbol: {max_news}")
    logger.info("=" * 60)
    
    all_news = []
    
    with ThreadPoolExecutor(max_workers=Config.MAX_WORKERS) as executor:
        future_to_symbol = {
            executor.submit(fetch_news_for_symbol, symbol, max_news): symbol 
            for symbol in symbols
        }
        
        for future in as_completed(future_to_symbol):
            try:
                news_list = future.result()
                if news_list:
                    all_news.extend(news_list)
            except Exception as e:
                pass
            
            time.sleep(Config.REQUEST_DELAY)
    
    # Remove duplicates by URL
    seen_urls = set()
    unique_news = []
    for news in all_news:
        if news['url'] not in seen_urls:
            seen_urls.add(news['url'])
            unique_news.append(news)
    
    logger.info(f"[RESULT] Total {len(unique_news)} news URLs collected (duplicates removed)")
    
    return unique_news


# ========================================
# 2. Selenium - Article Crawling
# ========================================

def setup_driver(headless=True):
    """Setup Selenium driver"""
    chrome_options = Options()
    
    if headless:
        chrome_options.add_argument("--headless=new")
        chrome_options.add_argument("--disable-gpu")
    
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_argument("--log-level=3")
    chrome_options.add_argument("--disable-logging")
    chrome_options.add_argument("--silent")
    
    driver = webdriver.Chrome(options=chrome_options)
    
    driver.execute_cdp_cmd('Page.addScriptToEvaluateOnNewDocument', {
        'source': "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
    })
    
    return driver


def is_external_article(driver):
    """Check if article is external link"""
    try:
        driver.find_element(By.XPATH, "//a[contains(text(), 'Continue Reading')]")
        return True
    except:
        pass
    
    try:
        driver.find_element(By.TAG_NAME, "article")
        return False
    except:
        return True


def crawl_article_content(driver, article_url):
    """Crawl article content"""
    CONTENT_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div"
    MORE_BUTTON_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[2]/button"
    EXTRA_CONTENT_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[3]"
    
    try:
        driver.get(article_url)
        time.sleep(3)
        
        # Check external article
        if is_external_article(driver):
            return {"success": False, "reason": "External article", "content": None}
        
        content_parts = []
        
        # Method 1: XPath
        try:
            content_div = driver.find_element(By.XPATH, CONTENT_XPATH)
            p_tags = content_div.find_elements(By.TAG_NAME, "p")
            for p in p_tags:
                text = p.text.strip()
                if text:
                    content_parts.append(text)
        except:
            pass
        
        # Click more button
        try:
            more_button = driver.find_element(By.XPATH, MORE_BUTTON_XPATH)
            more_button.click()
            time.sleep(1)
            
            extra_div = driver.find_element(By.XPATH, EXTRA_CONTENT_XPATH)
            extra_p_tags = extra_div.find_elements(By.TAG_NAME, "p")
            for p in extra_p_tags:
                text = p.text.strip()
                if text:
                    content_parts.append(text)
        except:
            pass
        
        # Method 2: body-wrap
        if not content_parts:
            try:
                body_wrap = driver.find_element(By.CSS_SELECTOR, ".body-wrap")
                p_tags = body_wrap.find_elements(By.TAG_NAME, "p")
                for p in p_tags:
                    text = p.text.strip()
                    if text and len(text) > 20:
                        content_parts.append(text)
            except:
                pass
        
        # Method 3: article tag
        if not content_parts:
            try:
                article = driver.find_element(By.TAG_NAME, "article")
                p_tags = article.find_elements(By.TAG_NAME, "p")
                for p in p_tags:
                    text = p.text.strip()
                    if text and len(text) > 30:
                        content_parts.append(text)
            except:
                pass
        
        if content_parts:
            return {"success": True, "content": "\n\n".join(content_parts)}
        else:
            return {"success": False, "reason": "Content extraction failed", "content": None}
        
    except Exception as e:
        return {"success": False, "reason": str(e), "content": None}


# ========================================
# 3. OpenAI API - Translation + Summary
# ========================================

def translate_and_summarize(client, content, title):
    """
    Translate English article to Korean with Markdown format
    
    Returns:
        dict: {
            "translated_content": "Markdown Korean content",
            "summary": "3-5 sentence summary"
        }
    """
    
    prompt = f"""Process the following English news article.

**Title**: {title}

**Content**:
{content}

---

**Requirements**:

1. **translated_content**: Translate the entire content to natural Korean in **Markdown format**.
   - Use ## subheadings where appropriate
   - Use **bold** for important content
   - Use bullet lists (-) for key points
   - Clearly display numbers and statistics
   - Use > blockquotes for quotes

2. **summary**: Summarize key content in 3-5 sentences (plain text, Korean)

---

**Response format** (output only JSON, no other text):
{{
    "translated_content": "Markdown formatted translated content",
    "summary": "3-5 sentence summary"
}}
"""
    
    try:
        response = client.chat.completions.create(
            model=Config.OPENAI_MODEL,
            messages=[
                {
                    "role": "system", 
                    "content": "You are a professional financial news translator. Always respond in valid JSON format only, without any markdown code blocks or extra text."
                },
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=4000
        )
        
        result_text = response.choices[0].message.content.strip()
        
        # Remove code blocks if present
        if result_text.startswith("```"):
            lines = result_text.split("\n")
            result_text = "\n".join(lines[1:-1])
        
        result = json.loads(result_text)
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"[ERROR] JSON parse error: {e}")
        return None
    except Exception as e:
        logger.error(f"[ERROR] OpenAI API error: {e}")
        return None


# ========================================
# 4. Encoding
# ========================================

def encode_news_detail(url, summary, publisher, full_content):
    """gzip + URL-safe Base64 encoding"""
    try:
        data_to_encode = {
            'url': url,
            'summary': summary,
            'publisher': publisher,
            'full_content': full_content
        }
        
        json_str = json.dumps(data_to_encode, ensure_ascii=False)
        compressed = gzip.compress(json_str.encode('utf-8'))
        encoded = base64.urlsafe_b64encode(compressed).decode('utf-8').rstrip('=')
        
        return encoded
        
    except Exception as e:
        logger.error(f"[ERROR] Encoding failed: {e}")
        return None


# ========================================
# Main Process
# ========================================

def process_news(news_list, headless=True):
    """Process news (crawl + translate + encode) with driver recovery"""
    logger.info("=" * 60)
    logger.info("[STEP 2-4] Crawling + Translation + Encoding")
    logger.info(f"[CONFIG] Total {len(news_list)} news to process")
    logger.info("=" * 60)
    
    if not news_list:
        return []
    
    # OpenAI client
    try:
        openai_client = get_openai_client()
        logger.info("[OK] OpenAI client initialized")
    except Exception as e:
        logger.error(f"[FATAL] OpenAI client init failed: {e}")
        return []
    
    # Selenium driver
    driver = setup_driver(headless=headless)
    logger.info("[OK] Selenium driver initialized")
    
    successful_news = []
    skip_count = 0
    error_count = 0
    driver_restart_count = 0
    
    def is_driver_alive(drv):
        """Check if driver session is still valid"""
        try:
            _ = drv.current_url
            return True
        except:
            return False
    
    try:
        for idx, article in enumerate(news_list):
            url = article.get('url')
            title = article.get('title', 'No Title')
            symbol = article.get('symbol', 'N/A')
            
            # Progress output (for Spring Boot parsing)
            print(f"PROGRESS:{idx+1}/{len(news_list)}:{symbol}", flush=True)
            
            logger.info(f"[{idx+1}/{len(news_list)}] {symbol}: {title[:50]}...")
            
            if not url:
                error_count += 1
                continue
            
            # Check driver health and restart if needed
            if not is_driver_alive(driver):
                logger.warning("[WARN] Driver session invalid, restarting...")
                try:
                    driver.quit()
                except:
                    pass
                driver = setup_driver(headless=headless)
                driver_restart_count += 1
                logger.info(f"[OK] Driver restarted (count: {driver_restart_count})")
                time.sleep(2)
            
            # Step 2: Crawl (with retry)
            crawl_result = None
            for attempt in range(2):  # Max 2 attempts
                try:
                    crawl_result = crawl_article_content(driver, url)
                    break
                except Exception as e:
                    if 'invalid session' in str(e).lower() or 'no such session' in str(e).lower():
                        logger.warning(f"[WARN] Session error on attempt {attempt+1}, restarting driver...")
                        try:
                            driver.quit()
                        except:
                            pass
                        driver = setup_driver(headless=headless)
                        driver_restart_count += 1
                        time.sleep(2)
                    else:
                        crawl_result = {"success": False, "reason": str(e), "content": None}
                        break
            
            if crawl_result is None:
                crawl_result = {"success": False, "reason": "Max retries exceeded", "content": None}
            
            if not crawl_result['success']:
                logger.info(f"    [SKIP] {crawl_result['reason']}")
                skip_count += 1
                time.sleep(1)
                continue
            
            original_content = crawl_result['content']
            logger.info(f"    [OK] Crawled ({len(original_content)} chars)")
            
            # Step 3: Translate + Summarize
            translated_result = translate_and_summarize(openai_client, original_content, title)
            
            if not translated_result:
                logger.info(f"    [FAIL] Translation failed")
                error_count += 1
                time.sleep(Config.CRAWL_DELAY)
                continue
            
            translated_content = translated_result['translated_content']
            summary = translated_result['summary']
            logger.info(f"    [OK] Translated ({len(translated_content)} chars)")
            
            # Step 4: Encode
            encoded_data = encode_news_detail(
                url=article.get('url', ''),
                summary=summary,
                publisher=article.get('publisher', ''),
                full_content=translated_content
            )
            
            if not encoded_data:
                error_count += 1
                continue
            
            # Save result
            article['encoded_data'] = encoded_data
            article['summary'] = summary
            successful_news.append(article)
            
            logger.info(f"    [OK] Encoded")
            
            # Delay
            time.sleep(Config.CRAWL_DELAY)
            
            # Periodic driver restart to prevent memory issues (every 100 articles)
            if (idx + 1) % 100 == 0:
                logger.info(f"[INFO] Preventive driver restart at {idx+1} articles...")
                try:
                    driver.quit()
                except:
                    pass
                driver = setup_driver(headless=headless)
                driver_restart_count += 1
                time.sleep(2)
        
    finally:
        try:
            driver.quit()
        except:
            pass
        logger.info("[OK] Browser closed")
    
    logger.info("=" * 60)
    logger.info(f"[RESULT] Success: {len(successful_news)}, Skipped: {skip_count}, Failed: {error_count}")
    logger.info(f"[RESULT] Driver restarts: {driver_restart_count}")
    logger.info("=" * 60)
    
    return successful_news


def save_to_json(news_list):
    """Save to JSON file"""
    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        
        output_path = OUTPUT_DIR / Config.OUTPUT_FILE
        
        output_data = {
            'timestamp': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'total_news': len(news_list),
            'data': news_list
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"[SAVED] {output_path}")
        logger.info(f"[TOTAL] {len(news_list)} news")
        
        return str(output_path)
        
    except Exception as e:
        logger.error(f"[ERROR] Save failed: {e}")
        raise


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='News Collector')
    
    parser.add_argument(
        '--symbols',
        type=str,
        default='',
        help='Symbols to collect (comma separated). Empty for all.'
    )
    
    parser.add_argument(
        '--count',
        type=int,
        default=Config.DEFAULT_NEWS_PER_SYMBOL,
        help=f'News per symbol (default: {Config.DEFAULT_NEWS_PER_SYMBOL})'
    )
    
    parser.add_argument(
        '--headless',
        type=bool,
        default=True,
        help='Headless mode (default: True)'
    )
    
    # New: Date-based collection
    parser.add_argument(
        '--date',
        type=str,
        default='',
        help='Specific date to collect (YYYY-MM-DD). Reads from scanned_news.json'
    )
    
    return parser.parse_args()


def load_news_from_scan(target_date):
    """
    Load news for specific date from scanned_news.json
    
    Args:
        target_date: Date string (YYYY-MM-DD)
    
    Returns:
        List of news items for that date
    """
    scan_file = OUTPUT_DIR / 'scanned_news.json'
    
    if not scan_file.exists():
        raise FileNotFoundError(f"Scan file not found: {scan_file}. Run news_date_scanner.py first.")
    
    with open(scan_file, 'r', encoding='utf-8') as f:
        scan_data = json.load(f)
    
    news_by_date = scan_data.get('news_by_date', {})
    
    if target_date not in news_by_date:
        available_dates = list(news_by_date.keys())
        raise ValueError(f"Date {target_date} not found. Available: {available_dates}")
    
    return news_by_date[target_date]


def main():
    """Main function"""
    args = parse_arguments()
    
    # Mode: Date-based collection
    if args.date:
        print(f"[START] News Collector (Date Mode: {args.date})", flush=True)
        logger.info("=" * 60)
        logger.info(f"News Collector - Date Mode: {args.date}")
        logger.info("=" * 60)
        
        try:
            # Load news from scanned_news.json
            news_list = load_news_from_scan(args.date)
            logger.info(f"[LOADED] {len(news_list)} news for {args.date}")
            
            if not news_list:
                print(f"[COMPLETE] No news for {args.date}", flush=True)
                return
            
            # Crawl + Translate + Encode
            processed_news = process_news(news_list, headless=args.headless)
            
            if not processed_news:
                print("[COMPLETE] No news processed", flush=True)
                return
            
            # Save JSON
            save_to_json(processed_news)
            
            print(f"[COMPLETE] Processed {len(processed_news)} news for {args.date}", flush=True)
            
        except Exception as e:
            print(f"[FATAL] {str(e)}", flush=True)
            logger.error(f"[FATAL] {e}")
            import traceback
            traceback.print_exc()
        
        return
    
    # Mode: Standard collection (existing logic)
    if args.symbols:
        symbols = [s.strip().upper() for s in args.symbols.split(',') if s.strip()]
        logger.info(f"[MODE] Specific symbols: {symbols}")
    else:
        symbols = load_symbols_from_csv()
        logger.info(f"[MODE] All symbols: {len(symbols)}")
    
    # Limit count
    max_news = min(args.count, Config.MAX_NEWS_PER_SYMBOL)
    max_news = max(max_news, 1)
    
    print("[START] News Collector", flush=True)
    logger.info("=" * 60)
    logger.info("News Collector Started")
    logger.info("=" * 60)
    logger.info(f"  - Symbols: {len(symbols)}")
    logger.info(f"  - News per symbol: {max_news}")
    logger.info(f"  - OpenAI model: {Config.OPENAI_MODEL}")
    logger.info("=" * 60)
    
    try:
        # Step 1: Collect news URLs
        news_list = collect_news_urls_parallel(symbols, max_news)
        
        if not news_list:
            logger.info("[INFO] No news to collect")
            print("[COMPLETE] No news to collect", flush=True)
            return
        
        # Step 2-4: Crawl + Translate + Encode
        processed_news = process_news(news_list, headless=args.headless)
        
        if not processed_news:
            logger.info("[INFO] No news processed")
            print("[COMPLETE] No news processed", flush=True)
            return
        
        # Step 5: Save JSON
        save_to_json(processed_news)
        
        print("[COMPLETE] News Collector finished", flush=True)
        logger.info("[DONE] News collection complete!")
        
    except Exception as e:
        print(f"[FATAL] {str(e)}", flush=True)
        logger.error(f"[FATAL] News collection failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
