"""
========================================
Track 2: Selenium 뉴스 본문 크롤링 (새 구조)
========================================

목적:
- news_links.json에서 뉴스 URL 읽기
- Selenium으로 본문 크롤링
- 외부 링크 기사는 스킵
- 더보기 버튼 클릭해서 전체 본문 가져오기
- gzip + URL-safe Base64 인코딩
- news_details.json 저장
"""

import sys
import os

# 출력 버퍼링 해제 (Java에서 실행 시 필요)
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(line_buffering=True)
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(line_buffering=True)
os.environ['PYTHONUNBUFFERED'] = '1'

import json
from datetime import datetime
import pytz
from pathlib import Path
import logging
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager
import time
import gzip
import base64

# 로깅 설정 (즉시 출력)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

kst = pytz.timezone('Asia/Seoul')

# ========================================
# 절대 경로 설정
# ========================================
SCRIPT_DIR = Path(__file__).parent.absolute()
OUTPUT_DIR = SCRIPT_DIR / 'output'
INPUT_FILE = OUTPUT_DIR / 'news_links.json'


class CrawlerConfig:
    """크롤러 설정"""
    OUTPUT_FILE = 'news_details.json'
    
    HEADLESS = True
    DELAY_BETWEEN_REQUESTS = 3
    PAGE_LOAD_TIMEOUT = 10
    
    # XPath 설정 (새 Yahoo Finance 구조)
    ARTICLE_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article"
    TITLE_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[1]/div[2]/h1"
    CONTENT_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div"
    MORE_BUTTON_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[2]/button"
    EXTRA_CONTENT_XPATH = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[3]"


# ========================================
# 인코딩 함수
# ========================================

def encode_news_detail(url, summary, publisher, full_content):
    """
    뉴스 상세 정보를 gzip + URL-safe Base64로 인코딩
    """
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
        logger.error(f"인코딩 실패: {e}")
        return None


def setup_driver(headless=True):
    """Selenium 드라이버 설정"""
    print("[DRIVER] Setting up Chrome driver...", flush=True)
    
    chrome_options = Options()
    
    if headless:
        chrome_options.add_argument("--headless=new")
        chrome_options.add_argument("--disable-gpu")
    
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    chrome_options.add_argument("--log-level=3")
    chrome_options.add_argument("--disable-logging")
    chrome_options.add_argument("--silent")
    
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=chrome_options
    )
    
    driver.execute_cdp_cmd('Page.addScriptToEvaluateOnNewDocument', {
        'source': '''
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            })
        '''
    })
    
    print("[DRIVER] ✅ Chrome driver initialized", flush=True)
    logger.info("✅ Selenium driver initialized")
    
    return driver


def is_external_article(driver):
    """외부 링크 기사인지 확인 (Continue Reading 버튼 있는지)"""
    try:
        driver.find_element(By.XPATH, "//a[contains(text(), 'Continue Reading')]")
        return True
    except:
        return False


def crawl_article_content(driver, article_url, timeout=10):
    """기사 페이지 크롤링 (새 구조)"""
    try:
        driver.get(article_url)
        time.sleep(3)
        
        result = {
            'full_content': None,
            'crawled_at': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'skipped': False,
            'skip_reason': None
        }
        
        # 외부 링크 기사 체크
        if is_external_article(driver):
            result['skipped'] = True
            result['skip_reason'] = 'External article (Continue Reading)'
            return result
        
        # ========================================
        # 방법 1: 새 Yahoo Finance 구조 (XPath)
        # ========================================
        content_parts = []
        
        try:
            # article 태그 확인
            article = driver.find_element(By.XPATH, CrawlerConfig.ARTICLE_XPATH)
            
            # 초기 본문 가져오기
            try:
                content_div = driver.find_element(By.XPATH, CrawlerConfig.CONTENT_XPATH)
                p_tags = content_div.find_elements(By.TAG_NAME, "p")
                
                for p in p_tags:
                    text = p.text.strip()
                    if text:
                        content_parts.append(text)
                
            except Exception as e:
                pass
            
            # 더보기 버튼 클릭
            try:
                more_button = driver.find_element(By.XPATH, CrawlerConfig.MORE_BUTTON_XPATH)
                more_button.click()
                time.sleep(1)
                
                # 추가 본문 가져오기
                extra_div = driver.find_element(By.XPATH, CrawlerConfig.EXTRA_CONTENT_XPATH)
                extra_p_tags = extra_div.find_elements(By.TAG_NAME, "p")
                
                for p in extra_p_tags:
                    text = p.text.strip()
                    if text:
                        content_parts.append(text)
                
            except Exception as e:
                pass
            
            if content_parts:
                result['full_content'] = "\n\n".join(content_parts)
                return result
                
        except Exception as e:
            pass
        
        # ========================================
        # 방법 2: body-wrap 클래스
        # ========================================
        try:
            body_wrap = driver.find_element(By.CSS_SELECTOR, ".body-wrap")
            p_tags = body_wrap.find_elements(By.TAG_NAME, "p")
            
            content_parts = []
            for p in p_tags:
                text = p.text.strip()
                if text and len(text) > 20:
                    content_parts.append(text)
            
            if content_parts:
                result['full_content'] = "\n\n".join(content_parts)
                return result
                
        except Exception as e:
            pass
        
        # ========================================
        # 방법 3: article 태그 내 모든 p 태그
        # ========================================
        try:
            article_element = driver.find_element(By.TAG_NAME, "article")
            p_tags = article_element.find_elements(By.TAG_NAME, "p")
            
            content_parts = []
            for p in p_tags:
                text = p.text.strip()
                if text and len(text) > 30:
                    content_parts.append(text)
            
            if content_parts:
                result['full_content'] = "\n\n".join(content_parts)
                return result
                
        except Exception as e:
            pass
        
        # ========================================
        # 방법 4: 모든 p 태그 (fallback)
        # ========================================
        try:
            p_tags = driver.find_elements(By.TAG_NAME, "p")
            
            content_parts = []
            for p in p_tags:
                text = p.text.strip()
                if text and len(text) > 50:
                    content_parts.append(text)
            
            if content_parts:
                result['full_content'] = "\n\n".join(content_parts[:20])
                return result
                
        except Exception as e:
            pass
        
        result['full_content'] = "Content extraction failed"
        
        return result
        
    except Exception as e:
        return {
            'full_content': f"Error: {str(e)}",
            'crawled_at': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'skipped': False,
            'skip_reason': None
        }


def load_news_links():
    """news_links.json 로드"""
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        news_list = data.get('data', [])
        print(f"[LOAD] Loaded {len(news_list)} news links", flush=True)
        logger.info(f"📂 Loaded {len(news_list)} news links from {INPUT_FILE}")
        
        return news_list
        
    except Exception as e:
        logger.error(f"❌ Failed to load news links: {e}")
        raise


def crawl_all_news_sequential(news_list, headless=True, delay=3):
    """순차적으로 뉴스 크롤링 + 인코딩"""
    print(f"[CRAWL] Starting crawling for {len(news_list)} articles", flush=True)
    logger.info("="*80)
    logger.info(f"[CRAWL] Starting sequential crawling")
    logger.info(f"[CONFIG] Total articles: {len(news_list)}")
    logger.info("="*80)
    
    if len(news_list) == 0:
        print("[CRAWL] No news to crawl", flush=True)
        logger.info("ℹ️  크롤링할 뉴스가 없습니다.")
        return []
    
    driver = setup_driver(headless=headless)
    
    success_count = 0
    skip_count = 0
    error_count = 0
    encoding_success = 0
    
    # 성공한 뉴스만 저장
    successful_news = []
    
    try:
        for idx, article in enumerate(news_list):
            url = article.get('url')
            title = article.get('title', 'No Title')[:40]
            symbol = article.get('symbol', 'N/A')
            
            # 진행률 출력 (Java에서 파싱용) - 항상 먼저 출력
            print(f"PROGRESS:{idx+1}/{len(news_list)}:{symbol}", flush=True)
            
            logger.info(f"📰 [{idx+1}/{len(news_list)}] {title}...")
            
            if not url:
                error_count += 1
                continue
            
            try:
                content_data = crawl_article_content(driver, url, timeout=10)
                
                # 외부 링크 기사 스킵
                if content_data.get('skipped'):
                    print(f"[SKIP] {symbol}: External article", flush=True)
                    skip_count += 1
                    continue
                
                article['full_content'] = content_data['full_content']
                article['crawled_at'] = content_data['crawled_at']
                
                if content_data['full_content'] and content_data['full_content'] != "Content extraction failed":
                    success_count += 1
                    
                    # 인코딩
                    encoded_data = encode_news_detail(
                        url=article.get('url', ''),
                        summary=article.get('summary', ''),
                        publisher=article.get('publisher', ''),
                        full_content=content_data['full_content']
                    )
                    
                    if encoded_data:
                        article['encoded_data'] = encoded_data
                        encoding_success += 1
                        successful_news.append(article)
                        print(f"[OK] {symbol}: {len(content_data['full_content'])} chars", flush=True)
                    
                else:
                    error_count += 1
                    print(f"[FAIL] {symbol}: Content extraction failed", flush=True)
                
            except Exception as e:
                error_count += 1
                print(f"[ERROR] {symbol}: {str(e)[:50]}", flush=True)
            
            if idx < len(news_list) - 1:
                time.sleep(delay)
        
        print(f"[STATS] Success: {success_count}, Skip: {skip_count}, Error: {error_count}", flush=True)
        logger.info(f"[STATS] 성공: {success_count}, 스킵: {skip_count}, 실패: {error_count}")
        
    finally:
        driver.quit()
        print("[DRIVER] Browser closed", flush=True)
    
    return successful_news


def save_news_details_to_json(news_list):
    """크롤링 완료된 뉴스를 JSON으로 저장"""
    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        
        output_path = OUTPUT_DIR / CrawlerConfig.OUTPUT_FILE
        
        output_data = {
            'timestamp': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'total_news': len(news_list),
            'data': news_list
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"[SAVE] Saved {len(news_list)} news to {output_path}", flush=True)
        logger.info(f"[SAVE] News details saved: {output_path}")
        
        return str(output_path)
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to save news details: {e}")
        raise


def main():
    """메인 함수"""
    print("[START] News Detail Crawler", flush=True)
    logger.info("="*80)
    logger.info("Track 2: News Detail Crawler Started")
    logger.info("="*80)
    
    try:
        # 1. 뉴스 링크 로드
        news_list = load_news_links()
        
        # 2. 크롤링 (외부 링크는 스킵, 성공한 것만 반환)
        crawled_news = crawl_all_news_sequential(
            news_list,
            headless=CrawlerConfig.HEADLESS,
            delay=CrawlerConfig.DELAY_BETWEEN_REQUESTS
        )
        
        # 3. JSON 저장 (성공한 뉴스만)
        save_news_details_to_json(crawled_news)
        
        print("[COMPLETE] News Detail Crawler finished", flush=True)
        logger.info("✅ Track 2 Completed Successfully")
        
    except Exception as e:
        print(f"[FATAL] {str(e)}", flush=True)
        logger.error(f"❌ Track 2 failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
