"""
========================================
Track 2: Selenium 뉴스 본문 크롤링
========================================

수정 사항:
- 인코딩 로직 추가 (gzip + URL-safe Base64)
- JSON 구조 변경 (encoded_data 필드 추가)
"""

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
import gzip  # 추가
import base64  # 추가

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
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


# ========================================
# 인코딩 함수 추가
# ========================================

def encode_news_detail(url, summary, publisher, full_content):
    """
    뉴스 상세 정보를 gzip + URL-safe Base64로 인코딩
    
    Args:
        url: 원본 기사 URL
        summary: 요약
        publisher: 출처
        full_content: 본문
    
    Returns:
        str: 인코딩된 문자열
    """
    try:
        # 인코딩할 데이터
        data_to_encode = {
            'url': url,
            'summary': summary,
            'publisher': publisher,
            'full_content': full_content
        }
        
        # JSON 문자열로 변환
        json_str = json.dumps(data_to_encode, ensure_ascii=False)
        
        # gzip 압축
        compressed = gzip.compress(json_str.encode('utf-8'))
        
        # URL-safe Base64 인코딩 (패딩 제거)
        encoded = base64.urlsafe_b64encode(compressed).decode('utf-8').rstrip('=')
        
        return encoded
        
    except Exception as e:
        logger.error(f"인코딩 실패: {e}")
        return None


def setup_driver(headless=True):
    """Selenium 드라이버 설정"""
    chrome_options = Options()
    
    if headless:
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--disable-gpu")
    
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    chrome_options.add_argument("--log-level=3")
    
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
    
    logger.info("✅ Selenium driver initialized")
    
    return driver


def crawl_article_content(driver, article_url, timeout=10):
    """기사 페이지 크롤링"""
    try:
        driver.get(article_url)
        time.sleep(2)
        
        wait = WebDriverWait(driver, timeout)
        
        result = {
            'full_content': None,
            'crawled_at': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # 방법 1: Yahoo Finance 기사 구조
        try:
            content_div = driver.find_element(
                By.XPATH, 
                "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[1]"
            )
            p_tags = content_div.find_elements(By.TAG_NAME, "p")
            
            content_parts = []
            for p in p_tags:
                text = p.text.strip()
                if text:
                    content_parts.append(text)
            
            if content_parts:
                result['full_content'] = "\n\n".join(content_parts)
                return result
                
        except Exception as e:
            logger.debug(f"    Method 1 failed: {e}")
        
        # 방법 2: article 태그 내 모든 p 태그
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
            logger.debug(f"    Method 2 failed: {e}")
        
        # 방법 3: 모든 p 태그
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
            logger.debug(f"    Method 3 failed: {e}")
        
        logger.warning(f"    ⚠️  Failed to extract content from: {article_url[:80]}...")
        result['full_content'] = "Content extraction failed"
        
        return result
        
    except Exception as e:
        logger.error(f"    ❌ Crawling error: {e}")
        return {
            'full_content': f"Error: {str(e)}",
            'crawled_at': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
        }


def load_news_links():
    """news_links.json 로드"""
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        news_list = data.get('data', [])
        logger.info(f"📂 Loaded {len(news_list)} news links from {INPUT_FILE}")
        
        return news_list
        
    except Exception as e:
        logger.error(f"❌ Failed to load news links: {e}")
        raise


def crawl_all_news_sequential(news_list, headless=True, delay=3):
    """순차적으로 뉴스 크롤링 + 인코딩"""
    logger.info("="*80)
    logger.info(f"[CRAWL] Starting sequential crawling")
    logger.info(f"[CONFIG] Total articles: {len(news_list)}")
    logger.info(f"[CONFIG] Delay: {delay}s")
    logger.info(f"[CONFIG] Headless: {headless}")
    logger.info("="*80)
    
    driver = setup_driver(headless=headless)
    
    success_count = 0
    error_count = 0
    encoding_success = 0
    encoding_fail = 0
    
    try:
        for idx, article in enumerate(news_list):
            url = article.get('url')
            
            logger.info(f"\n📰 [{idx+1}/{len(news_list)}] {article.get('title', 'No Title')[:60]}...")
            logger.info(f"    🔗 {url[:80]}...")
            
            if not url:
                logger.warning(f"    ⚠️  No URL, skipping")
                error_count += 1
                continue
            
            try:
                # 크롤링
                content_data = crawl_article_content(driver, url, timeout=10)
                
                article['full_content'] = content_data['full_content']
                article['crawled_at'] = content_data['crawled_at']
                
                if content_data['full_content'] and content_data['full_content'] != "Content extraction failed":
                    logger.info(f"    ✅ Success: {len(content_data['full_content'])} chars")
                    success_count += 1
                    
                    # ========================================
                    # 인코딩 추가
                    # ========================================
                    encoded_data = encode_news_detail(
                        url=article.get('url', ''),
                        summary=article.get('summary', ''),
                        publisher=article.get('publisher', ''),
                        full_content=content_data['full_content']
                    )
                    
                    if encoded_data:
                        article['encoded_data'] = encoded_data
                        logger.info(f"    🔐 Encoded: {len(encoded_data)} chars")
                        encoding_success += 1
                    else:
                        article['encoded_data'] = None
                        logger.warning(f"    ⚠️  Encoding failed")
                        encoding_fail += 1
                    
                else:
                    logger.warning(f"    ⚠️  Failed to extract content")
                    article['encoded_data'] = None
                    error_count += 1
                
            except Exception as e:
                logger.error(f"    ❌ Error: {e}")
                article['full_content'] = f"Error: {str(e)}"
                article['crawled_at'] = datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S')
                article['encoded_data'] = None
                error_count += 1
            
            if idx < len(news_list) - 1:
                logger.info(f"    ⏱️  Waiting {delay}s...")
                time.sleep(delay)
        
        logger.info("\n" + "="*80)
        logger.info(f"[STATS] Crawling Success: {success_count}, Errors: {error_count}")
        logger.info(f"[STATS] Encoding Success: {encoding_success}, Errors: {encoding_fail}")
        logger.info("="*80)
        
    finally:
        driver.quit()
        logger.info("🔒 Browser closed")
    
    return news_list


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
        
        logger.info("="*80)
        logger.info(f"[SAVE] News details saved: {output_path}")
        logger.info(f"[STATS] Total news: {len(news_list)}")
        logger.info("="*80)
        
        return str(output_path)
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to save news details: {e}")
        raise


def main():
    """메인 함수"""
    logger.info("="*80)
    logger.info("Track 2: News Detail Crawler Started")
    logger.info("="*80)
    logger.info(f"Configuration:")
    logger.info(f"  - Script dir: {SCRIPT_DIR}")
    logger.info(f"  - Input file: {INPUT_FILE}")
    logger.info(f"  - Output dir: {OUTPUT_DIR}")
    logger.info(f"  - Headless: {CrawlerConfig.HEADLESS}")
    logger.info(f"  - Delay: {CrawlerConfig.DELAY_BETWEEN_REQUESTS}s")
    logger.info("="*80)
    
    try:
        news_list = load_news_links()
        
        # 테스트: 처음 50개만 (필요시 주석 처리)
        # news_list = news_list[:50]
        
        crawled_news = crawl_all_news_sequential(
            news_list,
            headless=CrawlerConfig.HEADLESS,
            delay=CrawlerConfig.DELAY_BETWEEN_REQUESTS
        )
        
        save_news_details_to_json(crawled_news)
        
        logger.info("="*80)
        logger.info("✅ Track 2 Completed Successfully")
        logger.info("="*80)
        
    except Exception as e:
        logger.error(f"❌ Track 2 failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()