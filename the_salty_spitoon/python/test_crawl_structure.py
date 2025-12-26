"""
새로운 Yahoo Finance 뉴스 페이지 구조 테스트
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
print("Yahoo Finance 새 뉴스 페이지 구조 테스트")
print("=" * 70)

# 테스트할 URL (news_links.json에서 가져온 URL)
test_url = "https://finance.yahoo.com/m/981624e7-b136-3579-a856-a931906fd2bf/stock-market-hits-record.html"

driver = setup_driver()

try:
    print(f"\n📡 URL: {test_url}")
    driver.get(test_url)
    time.sleep(3)
    
    print(f"\n📄 페이지 제목: {driver.title}")
    
    # 방법 1: 사용자가 분석한 ul/li 구조
    print("\n" + "=" * 70)
    print("📋 방법 1: ul > li 구조 (여러 기사)")
    print("=" * 70)
    
    try:
        ul_xpath = "/html/body/div[2]/div[3]/main/section/section/section/section/div/ul"
        ul_element = driver.find_element(By.XPATH, ul_xpath)
        li_elements = ul_element.find_elements(By.TAG_NAME, "li")
        print(f"✅ li 태그 개수: {len(li_elements)}")
        
        for i, li in enumerate(li_elements[:3]):  # 처음 3개만
            print(f"\n--- 기사 [{i+1}] ---")
            
            # 제목
            try:
                h1 = li.find_element(By.TAG_NAME, "h1")
                print(f"  제목: {h1.text[:60]}...")
            except:
                print("  제목: (없음)")
            
            # 출처
            try:
                # div[1]/div[2] 안에서 출처 찾기
                source_div = li.find_element(By.CSS_SELECTOR, "article div:first-child div:nth-child(2)")
                source_text = source_div.text.split('\n')[0] if source_div.text else "N/A"
                print(f"  출처: {source_text[:30]}")
            except:
                print("  출처: (없음)")
            
            # 본문
            try:
                article = li.find_element(By.TAG_NAME, "article")
                # div[3]/div 안의 텍스트
                content_div = article.find_element(By.CSS_SELECTOR, "div:nth-child(3) > div")
                p_tags = content_div.find_elements(By.TAG_NAME, "p")
                if p_tags:
                    print(f"  본문 p태그: {len(p_tags)}개")
                    print(f"  첫 번째 p: {p_tags[0].text[:80]}..." if p_tags[0].text else "  (빈 텍스트)")
                else:
                    # p 태그가 없으면 다른 방법
                    all_text = content_div.text[:200]
                    print(f"  본문 (텍스트): {all_text}...")
            except Exception as e:
                print(f"  본문: (에러: {e})")
                
    except Exception as e:
        print(f"❌ ul/li 구조 없음: {e}")
    
    # 방법 2: 기존 article 구조
    print("\n" + "=" * 70)
    print("📋 방법 2: 기존 article 구조")
    print("=" * 70)
    
    try:
        # 기존 XPath
        content_div = driver.find_element(
            By.XPATH, 
            "/html/body/div[2]/div[3]/main/section/section/section/section/div/article/div[3]/div/div[1]"
        )
        p_tags = content_div.find_elements(By.TAG_NAME, "p")
        print(f"✅ p 태그 개수: {len(p_tags)}")
        if p_tags:
            print(f"첫 번째 p: {p_tags[0].text[:100]}...")
    except Exception as e:
        print(f"❌ 기존 구조 없음: {e}")
    
    # 방법 3: CSS Selector로 caas-body 찾기
    print("\n" + "=" * 70)
    print("📋 방법 3: caas-body 클래스")
    print("=" * 70)
    
    try:
        caas_body = driver.find_element(By.CSS_SELECTOR, ".caas-body")
        p_tags = caas_body.find_elements(By.TAG_NAME, "p")
        print(f"✅ caas-body p 태그: {len(p_tags)}개")
        if p_tags:
            print(f"첫 번째 p: {p_tags[0].text[:100]}...")
    except Exception as e:
        print(f"❌ caas-body 없음: {e}")
    
    # 방법 4: 모든 article 태그
    print("\n" + "=" * 70)
    print("📋 방법 4: 모든 article 태그 탐색")
    print("=" * 70)
    
    try:
        articles = driver.find_elements(By.TAG_NAME, "article")
        print(f"✅ article 태그 개수: {len(articles)}")
        
        for i, article in enumerate(articles[:2]):
            print(f"\n--- Article [{i+1}] ---")
            p_tags = article.find_elements(By.TAG_NAME, "p")
            print(f"  p 태그: {len(p_tags)}개")
            if p_tags:
                for j, p in enumerate(p_tags[:2]):
                    print(f"    p[{j}]: {p.text[:60]}..." if p.text else f"    p[{j}]: (빈 텍스트)")
    except Exception as e:
        print(f"❌ article 없음: {e}")
    
    # 페이지 소스 일부 출력 (디버깅용)
    print("\n" + "=" * 70)
    print("📋 페이지 구조 확인")
    print("=" * 70)
    
    try:
        main = driver.find_element(By.TAG_NAME, "main")
        print(f"main 태그 HTML (처음 1000자):")
        print(main.get_attribute('innerHTML')[:1000])
    except:
        pass

finally:
    driver.quit()
    print("\n🔒 브라우저 종료")

print("\n" + "=" * 70)
