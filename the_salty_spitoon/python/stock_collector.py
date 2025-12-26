"""
========================================
주식 데이터 수집 모듈 (최종 수정 v2)
========================================
"""

import yfinance as yf
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
    종목 데이터 수집 (완전 재작성)
    
    ========================================
    핵심 수정:
    ========================================
    1. Ticker 객체 직접 사용
    2. history() 메서드 사용
    3. MultiIndex 문제 완전 회피
    """
    try:
        # ========================================
        # 1. Ticker 객체 생성
        # ========================================
        ticker = yf.Ticker(symbol)
        
        # ========================================
        # 2. 1분봉 데이터 다운로드
        # ========================================
        df = ticker.history(
            period='1d',
            interval='1m',
            auto_adjust=True,
            actions=False
        )
        
        if df.empty:
            logger.debug(f"  [SKIP] {symbol}: No data")
            return None
        
        if len(df) < 2:
            logger.debug(f"  [SKIP] {symbol}: Not enough data (only {len(df)} candles)")
            return None
        
        # ========================================
        # 3. 마지막에서 2번째 봉 사용
        # ========================================
        candle = df.iloc[-2]
        candle_time = df.index[-2]
        
        # 타임존 처리
        if isinstance(candle_time, pd.Timestamp):
            if candle_time.tzinfo is None:
                candle_time = est.localize(candle_time.to_pydatetime())
            else:
                candle_time = candle_time.to_pydatetime()
        
        candle_time_kst = candle_time.astimezone(kst)
        
        # ========================================
        # 4. OHLCV 추출 (단일 값으로 확정)
        # ========================================
        try:
            # Ticker.history()는 항상 scalar 반환
            open_price = float(candle['Open'])
            high_price = float(candle['High'])
            low_price = float(candle['Low'])
            close_price = float(candle['Close'])
            volume = int(candle['Volume'])
            
        except Exception as e:
            logger.error(f"  [ERROR] {symbol}: Failed to extract OHLCV: {e}")
            logger.error(f"  [DEBUG] Candle type: {type(candle)}")
            logger.error(f"  [DEBUG] Open type: {type(candle['Open'])}")
            return None
        
        # ========================================
        # 5. 데이터 검증
        # ========================================
        
        # Volume = 0 스킵
        if volume == 0:
            logger.debug(f"  [SKIP] {symbol}: Volume = 0")
            return None
        
        # 가격 범위 체크
        MIN_PRICE = 1.0
        MAX_PRICE = 100000.0
        
        if not (MIN_PRICE <= close_price <= MAX_PRICE):
            logger.error(f"  [INVALID] {symbol}: Price out of range: ${close_price:.2f}")
            return None
        
        # OHLC 관계 검증
        if high_price < low_price:
            logger.error(f"  [INVALID] {symbol}: High < Low")
            return None
        
        if high_price < close_price or high_price < open_price:
            logger.error(f"  [INVALID] {symbol}: High price inconsistent")
            return None
        
        if low_price > close_price or low_price > open_price:
            logger.error(f"  [INVALID] {symbol}: Low price inconsistent")
            return None
        
        # ========================================
        # 6. 정상 데이터 생성
        # ========================================
        candle_data = {
            'timestamp': candle_time_kst.strftime('%Y-%m-%d %H:%M:%S'),
            'open': round(open_price, 4),
            'high': round(high_price, 4),
            'low': round(low_price, 4),
            'close': round(close_price, 4),
            'volume': volume
        }
        
        logger.info(f"  [OK] {symbol}: ${candle_data['close']:.2f} @ {candle_data['timestamp']} (vol={volume:,})")
        
        return candle_data
        
    except Exception as e:
        logger.error(f"  [ERROR] {symbol}: {e}")
        import traceback
        traceback.print_exc()
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
    print("Stock Collector - Test")
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