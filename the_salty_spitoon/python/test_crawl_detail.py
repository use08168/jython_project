"""
Yahoo Finance 뉴스 페이지 상세 구조 분석
"""
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

def setup_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_argument("--log-level=3")
    
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=chrome_options
    )
    return driver

print("=" * 70)
print("Yahoo Finance 뉴스 페이지 상세 분석")
print("=" * 70)

test_url = "https://finance.yahoo.com/m/981624e7-b136-3579-a856-a931906fd2bf/stock-market-hits-record.html"

driver = setup_driver()

try:
    print(f"\n📡 URL: {test_url}")
    driver.get(test_url)
    time.sleep(5)  # 더 오래 대기
    
    print(f"\n📄 페이지 제목: {driver.title}")
    
    # article 태그 내부 전체 구조 확인
    print("\n" + "=" * 70)
    print("📋 article 태그 내부 구조")
    print("=" * 70)
    
    try:
        article = driver.find_element(By.TAG_NAME, "article")
        
        # 모든 div 찾기
        divs = article.find_elements(By.TAG_NAME, "div")
        print(f"div 개수: {len(divs)}")
        
        # 클래스 목록 출력
        print("\n주요 클래스:")
        seen_classes = set()
        for div in divs[:30]:
            cls = div.get_attribute("class")
            if cls and cls not in seen_classes:
                seen_classes.add(cls)
                text_preview = div.text[:50].replace('\n', ' ') if div.text else "(빈 텍스트)"
                print(f"  .{cls}: {text_preview}...")
        
        # body-wrap 또는 body 클래스 찾기
        print("\n" + "-" * 50)
        print("body 관련 요소 찾기:")
        
        body_elements = article.find_elements(By.CSS_SELECTOR, "[class*='body']")
        for elem in body_elements:
            cls = elem.get_attribute("class")
            text = elem.text[:200].replace('\n', ' ') if elem.text else "(없음)"
            print(f"\n  [{cls}]")
            print(f"  텍스트: {text}...")
        
        # content 관련 요소
        print("\n" + "-" * 50)
        print("content 관련 요소 찾기:")
        
        content_elements = article.find_elements(By.CSS_SELECTOR, "[class*='content']")
        for elem in content_elements[:5]:
            cls = elem.get_attribute("class")
            text = elem.text[:200].replace('\n', ' ') if elem.text else "(없음)"
            print(f"\n  [{cls}]")
            print(f"  텍스트: {text}...")
            
    except Exception as e:
        print(f"❌ 에러: {e}")
    
    # 본문 텍스트가 있을 법한 요소들
    print("\n" + "=" * 70)
    print("📋 긴 텍스트를 가진 요소 찾기")
    print("=" * 70)
    
    try:
        all_elements = driver.find_elements(By.XPATH, "//*")
        
        long_text_elements = []
        for elem in all_elements:
            try:
                text = elem.text
                if text and len(text) > 500:
                    tag = elem.tag_name
                    cls = elem.get_attribute("class") or "(no class)"
                    long_text_elements.append({
                        'tag': tag,
                        'class': cls,
                        'text_len': len(text),
                        'text_preview': text[:200].replace('\n', ' ')
                    })
            except:
                pass
        
        # 중복 제거 및 정렬
        seen = set()
        for item in sorted(long_text_elements, key=lambda x: x['text_len'], reverse=True)[:10]:
            key = (item['tag'], item['class'])
            if key not in seen:
                seen.add(key)
                print(f"\n[{item['tag']}] .{item['class']}")
                print(f"  길이: {item['text_len']} chars")
                print(f"  미리보기: {item['text_preview']}...")
                
    except Exception as e:
        print(f"❌ 에러: {e}")
    
    # 특정 클래스 시도
    print("\n" + "=" * 70)
    print("📋 특정 선택자 시도")
    print("=" * 70)
    
    selectors = [
        ".article-wrap",
        ".body-wrap",
        ".caas-body-section",
        ".caas-content-wrapper",
        "[data-testid='article-body']",
        ".atoms-wrapper",
        ".yf-1pe5jgt",  # 페이지에서 본 클래스
    ]
    
    for sel in selectors:
        try:
            elem = driver.find_element(By.CSS_SELECTOR, sel)
            text = elem.text[:300].replace('\n', ' ') if elem.text else "(없음)"
            print(f"\n✅ {sel}")
            print(f"   텍스트: {text}...")
        except:
            print(f"❌ {sel} - 없음")

finally:
    driver.quit()
    print("\n🔒 브라우저 종료")

print("\n" + "=" * 70)
