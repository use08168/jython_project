"""
news_links.json에서 가져온 실제 URL로 테스트
"""
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
import json
from pathlib import Path

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
print("news_links.json 실제 URL 테스트")
print("=" * 70)

# news_links.json에서 URL 가져오기
json_path = Path("python/output/news_links.json")
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# 처음 5개 URL 테스트
test_urls = [item['url'] for item in data['data'][:5]]

driver = setup_driver()

try:
    for i, url in enumerate(test_urls):
        print(f"\n{'='*70}")
        print(f"📡 [{i+1}/{len(test_urls)}] {url[:70]}...")
        driver.get(url)
        time.sleep(3)
        
        print(f"📄 제목: {driver.title}")
        
        # 외부 링크 체크 (Continue Reading 버튼 있는지)
        is_external = False
        try:
            continue_btn = driver.find_element(By.XPATH, "//a[contains(text(), 'Continue Reading')]")
            print("⚠️  외부 링크 기사 (Continue Reading) → 스킵!")
            is_external = True
        except:
            pass
        
        if is_external:
            continue
        
        print("✅ Yahoo 자체 기사")
        
        # article 태그 찾기 (여러 방법)
        article = None
        article_xpath = "/html/body/div[2]/div[3]/main/section/section/section/section/div/article"
        
        try:
            article = driver.find_element(By.XPATH, article_xpath)
            print("✅ article 태그 발견 (XPath)")
        except:
            try:
                article = driver.find_element(By.TAG_NAME, "article")
                print("✅ article 태그 발견 (TAG_NAME)")
            except:
                print("❌ article 태그 없음")
                continue
        
        # 1. 제목 (여러 방법 시도)
        print("\n--- 제목 ---")
        title = None
        try:
            title = driver.find_element(By.XPATH, f"{article_xpath}/div[1]/div[2]/h1").text
            print(f"✅ [방법1] {title[:50]}...")
        except:
            try:
                title = article.find_element(By.TAG_NAME, "h1").text
                print(f"✅ [방법2] {title[:50]}...")
            except:
                try:
                    title = driver.find_element(By.CSS_SELECTOR, ".cover-headline h1").text
                    print(f"✅ [방법3] {title[:50]}...")
                except:
                    print("❌ 제목 추출 실패")
        
        # 2. 본문 (여러 방법 시도)
        print("\n--- 본문 ---")
        content_parts = []
        
        # 방법 1: 지정 XPath
        try:
            content_div = driver.find_element(By.XPATH, f"{article_xpath}/div[3]/div/div")
            p_tags = content_div.find_elements(By.TAG_NAME, "p")
            for p in p_tags:
                if p.text.strip():
                    content_parts.append(p.text.strip())
            print(f"✅ [방법1] p 태그: {len(p_tags)}개")
        except:
            pass
        
        # 방법 2: body-wrap 클래스
        if not content_parts:
            try:
                body_wrap = driver.find_element(By.CSS_SELECTOR, ".body-wrap")
                p_tags = body_wrap.find_elements(By.TAG_NAME, "p")
                for p in p_tags:
                    if p.text.strip():
                        content_parts.append(p.text.strip())
                print(f"✅ [방법2] p 태그: {len(p_tags)}개")
            except:
                pass
        
        # 방법 3: article 내 모든 p 태그
        if not content_parts:
            try:
                p_tags = article.find_elements(By.TAG_NAME, "p")
                for p in p_tags:
                    text = p.text.strip()
                    if text and len(text) > 30:
                        content_parts.append(text)
                print(f"✅ [방법3] p 태그: {len(p_tags)}개")
            except:
                pass
        
        initial_content = "\n\n".join(content_parts)
        print(f"본문 길이: {len(initial_content)} chars")
        if initial_content:
            print(f"미리보기: {initial_content[:200]}...")
        
        # 3. 더보기 버튼
        print("\n--- 더보기 버튼 ---")
        try:
            # 여러 방법으로 더보기 버튼 찾기
            more_button = None
            try:
                more_button = driver.find_element(By.XPATH, f"{article_xpath}/div[3]/div/div[2]/button")
            except:
                try:
                    more_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Story continues')]")
                except:
                    try:
                        more_button = driver.find_element(By.CSS_SELECTOR, "button.readmore-button")
                    except:
                        pass
            
            if more_button:
                print(f"✅ 더보기 버튼: {more_button.text}")
                more_button.click()
                time.sleep(1)
                
                # 추가 본문
                try:
                    extra_div = driver.find_element(By.XPATH, f"{article_xpath}/div[3]/div/div[3]")
                    extra_p_tags = extra_div.find_elements(By.TAG_NAME, "p")
                    extra_parts = [p.text.strip() for p in extra_p_tags if p.text.strip()]
                    print(f"✅ 추가 본문: {len(extra_parts)}개 p태그, {sum(len(p) for p in extra_parts)} chars")
                except:
                    print("ℹ️  추가 본문 없음")
            else:
                print("ℹ️  더보기 버튼 없음 (짧은 기사)")
                
        except Exception as e:
            print(f"ℹ️  더보기 처리 중 에러: {e}")

finally:
    driver.quit()
    print("\n🔒 브라우저 종료")

print("\n" + "=" * 70)
