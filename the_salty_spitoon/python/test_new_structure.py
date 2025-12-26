"""
Yahoo Finance 뉴스 새 구조 테스트
"""
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
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
print("Yahoo Finance 뉴스 새 구조 테스트")
print("=" * 70)

# 테스트 URL들
test_urls = [
    # Yahoo 자체 기사 (전문 있음)
    "https://finance.yahoo.com/news/nvidia-makes-biggest-purchase-ever-060700043.html",
    # 외부 기사 (Continue Reading)
    "https://finance.yahoo.com/m/981624e7-b136-3579-a856-a931906fd2bf/stock-market-hits-record.html",
]

driver = setup_driver()

try:
    for url in test_urls:
        print(f"\n{'='*70}")
        print(f"📡 URL: {url[:70]}...")
        driver.get(url)
        time.sleep(3)
        
        print(f"📄 제목: {driver.title}")
        
        # 외부 링크 체크 (Continue Reading 버튼 있는지)
        try:
            continue_btn = driver.find_element(By.XPATH, "//a[contains(text(), 'Continue Reading')]")
            print("⚠️  외부 링크 기사 (Continue Reading) → 스킵!")
            continue
        except:
            print("✅ Yahoo 자체 기사")
        
        # 기사 구조 확인
        article_xpath = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article"
        
        try:
            article = driver.find_element(By.XPATH, article_xpath)
            print("✅ article 태그 발견")
        except:
            print("❌ article 태그 없음")
            continue
        
        # 1. 제목
        print("\n--- 제목 ---")
        try:
            title_xpath = f"{article_xpath}/div[1]/div[2]/h1"
            title = driver.find_element(By.XPATH, title_xpath).text
            print(f"✅ 제목: {title[:60]}...")
        except Exception as e:
            print(f"❌ 제목 없음: {e}")
        
        # 2. 작성자
        print("\n--- 작성자 ---")
        try:
            author_xpath = f"{article_xpath}/div[2]/div[1]/div/div[1]"
            author = driver.find_element(By.XPATH, author_xpath).text
            print(f"✅ 작성자: {author}")
        except Exception as e:
            print(f"❌ 작성자 없음: {e}")
        
        # 3. 발행일
        print("\n--- 발행일 ---")
        try:
            time_xpath = f"{article_xpath}/div[2]/div[1]/div/div[2]/time"
            pub_time = driver.find_element(By.XPATH, time_xpath).text
            print(f"✅ 발행일: {pub_time}")
        except Exception as e:
            print(f"❌ 발행일 없음: {e}")
        
        # 4. 본문 (초기)
        print("\n--- 본문 (초기) ---")
        try:
            content_xpath = f"{article_xpath}/div[3]/div/div"
            content_div = driver.find_element(By.XPATH, content_xpath)
            p_tags = content_div.find_elements(By.TAG_NAME, "p")
            print(f"✅ p 태그 개수: {len(p_tags)}")
            
            content_parts = []
            for p in p_tags:
                if p.text.strip():
                    content_parts.append(p.text.strip())
            
            initial_content = "\n\n".join(content_parts)
            print(f"초기 본문 ({len(initial_content)} chars):")
            print(initial_content[:300] + "..." if len(initial_content) > 300 else initial_content)
            
        except Exception as e:
            print(f"❌ 본문 없음: {e}")
            initial_content = ""
        
        # 5. 더보기 버튼 클릭
        print("\n--- 더보기 버튼 ---")
        try:
            button_xpath = f"{article_xpath}/div[3]/div/div[2]/button"
            more_button = driver.find_element(By.XPATH, button_xpath)
            print(f"✅ 더보기 버튼 발견: {more_button.text}")
            
            # 버튼 클릭
            more_button.click()
            time.sleep(1)
            print("✅ 버튼 클릭 완료")
            
            # 추가 본문 가져오기
            extra_xpath = f"{article_xpath}/div[3]/div/div[3]"
            extra_div = driver.find_element(By.XPATH, extra_xpath)
            extra_p_tags = extra_div.find_elements(By.TAG_NAME, "p")
            print(f"✅ 추가 p 태그 개수: {len(extra_p_tags)}")
            
            extra_parts = []
            for p in extra_p_tags:
                if p.text.strip():
                    extra_parts.append(p.text.strip())
            
            extra_content = "\n\n".join(extra_parts)
            print(f"추가 본문 ({len(extra_content)} chars):")
            print(extra_content[:300] + "..." if len(extra_content) > 300 else extra_content)
            
            # 전체 본문
            full_content = initial_content + "\n\n" + extra_content if extra_content else initial_content
            print(f"\n📝 전체 본문: {len(full_content)} chars")
            
        except Exception as e:
            print(f"ℹ️  더보기 버튼 없음 (짧은 기사): {e}")

finally:
    driver.quit()
    print("\n🔒 브라우저 종료")

print("\n" + "=" * 70)
