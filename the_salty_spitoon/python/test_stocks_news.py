"""
Yahoo Finance Most Active / Stocks News API 테스트
"""
import requests
import json
from datetime import datetime
import pytz

kst = pytz.timezone('Asia/Seoul')

print("=" * 60)
print("Yahoo Finance Stocks News API 테스트")
print("=" * 60)

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

# 방법 1: Stream API (Stock News Feed)
print("\n📡 방법 1: News Stream API")
try:
    url = "https://query1.finance.yahoo.com/v2/finance/news"
    params = {
        "category": "stock-markets",
        "count": 20
    }
    response = requests.get(url, headers=headers, params=params, timeout=10)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print(response.text[:500])
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 2: Trending Tickers News
print("\n📡 방법 2: Trending Tickers")
try:
    url = "https://query1.finance.yahoo.com/v1/finance/trending/US"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        quotes = data.get('finance', {}).get('result', [{}])[0].get('quotes', [])
        print(f"Trending: {[q.get('symbol') for q in quotes[:10]]}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 3: Market Summary News
print("\n📡 방법 3: Market Summary")
try:
    url = "https://query1.finance.yahoo.com/v6/finance/quote/marketSummary"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 4: News Category API
print("\n📡 방법 4: News Category (stocks)")
try:
    url = "https://query1.finance.yahoo.com/v1/finance/visualization"
    payload = {
        "category": "stocks"
    }
    response = requests.post(url, headers=headers, json=payload, timeout=10)
    print(f"Status: {response.status_code}")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 5: RSS Feed
print("\n📡 방법 5: Stock Market RSS Feed")
try:
    url = "https://finance.yahoo.com/rss/topstories"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    if response.status_code == 200 and len(response.text) > 100:
        print("✅ RSS 작동!")
        # XML 파싱
        import xml.etree.ElementTree as ET
        root = ET.fromstring(response.text)
        items = root.findall('.//item')
        print(f"뉴스 개수: {len(items)}")
        for item in items[:5]:
            title = item.find('title').text if item.find('title') is not None else 'N/A'
            pubDate = item.find('pubDate').text if item.find('pubDate') is not None else 'N/A'
            print(f"  - {pubDate[:16]} | {title[:50]}...")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 6: Stock News RSS
print("\n📡 방법 6: Stock News RSS")
try:
    url = "https://finance.yahoo.com/rss/stock-market-news"
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    if response.status_code == 200 and len(response.text) > 100 and '<?xml' in response.text:
        print("✅ RSS 작동!")
        import xml.etree.ElementTree as ET
        root = ET.fromstring(response.text)
        items = root.findall('.//item')
        print(f"뉴스 개수: {len(items)}")
        for item in items[:5]:
            title = item.find('title').text if item.find('title') is not None else 'N/A'
            pubDate = item.find('pubDate').text if item.find('pubDate') is not None else 'N/A'
            print(f"  - {pubDate[:16] if pubDate else 'N/A'} | {title[:50]}...")
except Exception as e:
    print(f"❌ 에러: {e}")

# 방법 7: Quote Summary with news
print("\n📡 방법 7: 여러 종목 한번에 Search (최신 뉴스)")
try:
    # 여러 인기 종목의 뉴스를 가져와서 병합
    symbols = ["NVDA", "AAPL", "TSLA", "MSFT", "GOOGL"]
    all_news = []
    
    for symbol in symbols:
        url = f"https://query1.finance.yahoo.com/v1/finance/search?q={symbol}&newsCount=5"
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            news = data.get('news', [])
            for item in news:
                item['search_symbol'] = symbol
                all_news.append(item)
    
    # 시간순 정렬
    all_news.sort(key=lambda x: x.get('providerPublishTime', 0), reverse=True)
    
    print(f"✅ 총 {len(all_news)}개 뉴스 (중복 포함)")
    print("\n최신 10개:")
    seen_titles = set()
    count = 0
    for item in all_news:
        title = item.get('title', 'N/A')
        if title in seen_titles:
            continue
        seen_titles.add(title)
        
        pub_time = item.get('providerPublishTime', 0)
        if pub_time:
            dt = datetime.fromtimestamp(pub_time, tz=pytz.UTC)
            dt_kst = dt.astimezone(kst)
            date_str = dt_kst.strftime('%m/%d %H:%M')
        else:
            date_str = "N/A"
        
        symbol = item.get('search_symbol', '')
        print(f"  [{date_str}] [{symbol}] {title[:45]}...")
        count += 1
        if count >= 10:
            break

except Exception as e:
    print(f"❌ 에러: {e}")

print("\n" + "=" * 60)
