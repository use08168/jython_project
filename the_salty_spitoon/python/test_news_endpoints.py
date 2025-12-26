"""
Yahoo Finance 뉴스 API 엔드포인트 테스트
Stocks News 섹션 데이터 가져오기
"""
import requests
import json
from datetime import datetime
import pytz

kst = pytz.timezone('Asia/Seoul')

print("=" * 60)
print("Yahoo Finance Stocks News API 테스트")
print("=" * 60)

symbol = "AAPL"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

# 방법 1: v2 News API
print("\n📡 방법 1: v2 Finance News API")
try:
    url = f"https://query2.finance.yahoo.com/v2/finance/news?symbols={symbol}"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        items = data.get('Content', {}).get('result', [])
        print(f"✅ {len(items)}개 뉴스 발견!")
        if items:
            for i, item in enumerate(items[:3]):
                title = item.get('title', 'N/A')
                pub_time = item.get('pubDate', '')
                print(f"  [{i+1}] {title[:50]}... ({pub_time})")
    else:
        print(f"Response: {response.text[:300]}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 2: quoteSummary news module
print("\n📡 방법 2: quoteSummary (news 모듈)")
try:
    url = f"https://query1.finance.yahoo.com/v11/finance/quoteSummary/{symbol}?modules=upgradeDowngradeHistory"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text[:300]}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 3: 종목 페이지 뉴스 (다른 엔드포인트)
print("\n📡 방법 3: v1 Finance Quote News")
try:
    url = f"https://query1.finance.yahoo.com/v1/finance/quoteNews/{symbol}?count=10"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False)[:500])
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 4: Screener News
print("\n📡 방법 4: Finance Screener")
try:
    url = "https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 5: 기존 Search API 최신 뉴스 날짜 확인
print("\n📡 방법 5: Search API (현재 사용 중) - 날짜 확인")
try:
    url = f"https://query1.finance.yahoo.com/v1/finance/search?q={symbol}&newsCount=10"
    response = requests.get(url, headers=headers, timeout=10)
    
    if response.status_code == 200:
        data = response.json()
        news = data.get('news', [])
        print(f"✅ {len(news)}개 뉴스")
        for i, item in enumerate(news[:5]):
            title = item.get('title', 'N/A')
            pub_time = item.get('providerPublishTime', 0)
            if pub_time:
                dt = datetime.fromtimestamp(pub_time, tz=pytz.UTC)
                dt_kst = dt.astimezone(kst)
                date_str = dt_kst.strftime('%Y-%m-%d %H:%M')
            else:
                date_str = "N/A"
            print(f"  [{i+1}] {date_str} - {title[:40]}...")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 6: News Stream API
print("\n📡 방법 6: News Stream API")
try:
    url = f"https://query1.finance.yahoo.com/v2/finance/news?symbols={symbol}&count=20"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"Keys: {data.keys()}")
        print(json.dumps(data, indent=2, ensure_ascii=False)[:800])
except Exception as e:
    print(f"❌ 에러: {e}")

print("\n" + "=" * 60)
