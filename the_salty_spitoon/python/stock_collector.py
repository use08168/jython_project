"""
========================================
주식 데이터 수집 모듈 (Direct API Version)
========================================
yfinance 대신 Yahoo Finance API 직접 호출
"""

import requests
from websocket_publisher import WebSocketPublisher
import logging
from datetime import datetime
import pytz
import pandas as pd
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

kst = pytz.timezone('Asia/Seoul')
est = pytz.timezone('US/Eastern')

# API 요청 헤더
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}


def load_symbols_from_csv():
    """CSV에서 종목 로드"""
    try:
        possible_paths = [
            'nasdaq100_tickers.csv',
            'python/nasdaq100_tickers.csv',
            '../nasdaq100_tickers.csv',
            'data/nasdaq100_tickers.csv'
        ]
        
        csv_file = None
        for path in possible_paths:
            if Path(path).exists():
                csv_file = path
                break
        
        if csv_file is None:
            raise FileNotFoundError("nasdaq100_tickers.csv not found")
        
        logger.info(f"📂 Loading symbols from: {csv_file}")
        
        df = pd.read_csv(csv_file)
        symbols = df['symbol'].str.strip().str.upper().tolist()
        
        logger.info(f"✅ Loaded {len(symbols)} symbols")
        
        return symbols
        
    except Exception as e:
        logger.error(f"❌ Failed to load CSV: {e}")
        raise


def collect_stock_data(symbol):
    """
    종목 데이터 수집 (Direct API Version)
    
    Yahoo Finance API를 직접 호출하여 데이터 수집
    """
    try:
        # ========================================
        # 1. Yahoo Finance API 직접 호출
        # ========================================
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
        params = {
            "interval": "1m",
            "range": "1d"
        }
        
        response = requests.get(url, params=params, headers=HEADERS, timeout=10)
        
        if response.status_code != 200:
            logger.error(f"  [ERROR] {symbol}: HTTP {response.status_code}")
            return None
        
        data = response.json()
        
        # ========================================
        # 2. 응답 검증
        # ========================================
        if "chart" not in data or "result" not in data["chart"]:
            logger.error(f"  [ERROR] {symbol}: Invalid API response")
            return None
        
        result = data["chart"]["result"]
        if not result:
            logger.debug(f"  [SKIP] {symbol}: No data")
            return None
        
        chart_data = result[0]
        
        # ========================================
        # 3. 타임스탬프와 가격 데이터 추출
        # ========================================
        timestamps = chart_data.get("timestamp", [])
        indicators = chart_data.get("indicators", {})
        quote = indicators.get("quote", [{}])[0]
        
        opens = quote.get("open", [])
        highs = quote.get("high", [])
        lows = quote.get("low", [])
        closes = quote.get("close", [])
        volumes = quote.get("volume", [])
        
        if not timestamps or len(timestamps) < 2:
            logger.debug(f"  [SKIP] {symbol}: Not enough data")
            return None
        
        # ========================================
        # 4. None이 아닌 마지막 완성된 봉 찾기
        # ========================================
        candle_data = None
        
        # 역순으로 탐색 (최신 → 과거)
        for idx in range(-1, -len(timestamps) - 1, -1):
            ts = timestamps[idx] if abs(idx) <= len(timestamps) else None
            o = opens[idx] if abs(idx) <= len(opens) else None
            h = highs[idx] if abs(idx) <= len(highs) else None
            l = lows[idx] if abs(idx) <= len(lows) else None
            c = closes[idx] if abs(idx) <= len(closes) else None
            v = volumes[idx] if abs(idx) <= len(volumes) else None
            
            # 모든 데이터가 있고 volume > 0인 봉 찾기
            if ts and o and h and l and c and v and v > 0:
                open_price = float(o)
                high_price = float(h)
                low_price = float(l)
                close_price = float(c)
                volume = int(v)
                
                # 가격 범위 체크
                MIN_PRICE = 1.0
                MAX_PRICE = 100000.0
                
                if not (MIN_PRICE <= close_price <= MAX_PRICE):
                    continue
                
                # OHLC 관계 검증
                if high_price < low_price:
                    continue
                
                # 타임스탬프 변환
                dt = datetime.fromtimestamp(ts, tz=pytz.UTC)
                candle_time_kst = dt.astimezone(kst)
                
                candle_data = {
                    'timestamp': candle_time_kst.strftime('%Y-%m-%d %H:%M:%S'),
                    'open': round(open_price, 4),
                    'high': round(high_price, 4),
                    'low': round(low_price, 4),
                    'close': round(close_price, 4),
                    'volume': volume
                }
                
                break  # 첫 번째 유효한 봉 발견 시 종료
        
        if candle_data:
            logger.info(f"  [OK] {symbol}: ${candle_data['close']:.2f} @ {candle_data['timestamp']} (vol={candle_data['volume']:,})")
            return candle_data
        else:
            logger.debug(f"  [SKIP] {symbol}: No valid candle found")
            return None
        
    except requests.exceptions.Timeout:
        logger.error(f"  [TIMEOUT] {symbol}")
        return None
    except Exception as e:
        logger.error(f"  [ERROR] {symbol}: {e}")
        return None


def collect_all_stocks_parallel(symbols, max_workers=20):
    """병렬 수집"""
    logger.info(f"[PARALLEL] Starting with {max_workers} workers")
    
    results = {}
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_symbol = {
            executor.submit(collect_stock_data, symbol): symbol 
            for symbol in symbols
        }
        
        for future in as_completed(future_to_symbol):
            symbol = future_to_symbol[future]
            try:
                data = future.result()
                if data:
                    results[symbol] = data
            except Exception as e:
                logger.error(f"  [ERROR] {symbol}: {e}")
    
    return results


def collect_all_stocks():
    """메인 함수"""
    try:
        symbols = load_symbols_from_csv()
    except Exception as e:
        logger.error(f"Failed to load symbols: {e}")
        return 0, 0
    
    logger.info("[COLLECT] Starting collection for all symbols")
    logger.info(f"[COLLECT] Total symbols: {len(symbols)}")
    
    results = collect_all_stocks_parallel(symbols, max_workers=20)
    
    success_count = len(results)
    error_count = len(symbols) - success_count
    
    publisher = WebSocketPublisher()
    
    for symbol, data in results.items():
        publisher.publish(symbol, data)
    
    logger.info("")
    logger.info("[SAVE] Writing JSON file...")
    
    if publisher.save_all():
        logger.info("[OK] JSON file saved successfully")
    else:
        logger.error("[ERROR] Failed to save JSON file")
    
    return success_count, error_count


# 테스트
if __name__ == "__main__":
    print("="*60)
    print("Stock Collector - Direct API Test")
    print("="*60)
    
    print("\n[TEST] Collecting AAPL...")
    data = collect_stock_data('AAPL')
    
    if data:
        print(f"✅ Success:")
        print(f"   Time: {data['timestamp']}")
        print(f"   OHLC: {data['open']:.2f} / {data['high']:.2f} / {data['low']:.2f} / {data['close']:.2f}")
        print(f"   Vol: {data['volume']:,}")
    else:
        print("❌ No data")
    
    print("\n[TEST] Collecting TSLA...")
    data = collect_stock_data('TSLA')
    
    if data:
        print(f"✅ Success:")
        print(f"   Time: {data['timestamp']}")
        print(f"   OHLC: {data['open']:.2f} / {data['high']:.2f} / {data['low']:.2f} / {data['close']:.2f}")
        print(f"   Vol: {data['volume']:,}")
    else:
        print("❌ No data")
    
    print("\n" + "="*60)
