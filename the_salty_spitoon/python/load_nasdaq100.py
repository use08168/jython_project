"""
========================================
NASDAQ 100 전체 종목 과거 데이터 로드
========================================

목적:
- NASDAQ 100 전체 종목 과거 데이터 일괄 수집
- API 부하 방지 (종목당 2초 대기)

작성자: The Salty Spitoon Team
작성일: 2025-12-23 (API 대기 시간 추가)
"""

import csv
import json
import yfinance as yf
import pytz
from datetime import datetime, timedelta
from pathlib import Path
import logging
import time  # ← 추가

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class Nasdaq100Loader:
    """
    NASDAQ 100 전체 종목 데이터 로더
    """
    
    def __init__(self):
        self.kst = pytz.timezone('Asia/Seoul')
        self.utc = pytz.UTC
        self.csv_file = Path("python/nasdaq100_tickers.csv")
        self.output_dir = Path("python/results")
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def load_all(self, hours=720):
        """
        전체 종목 과거 데이터 수집
        
        Args:
            hours (int): 수집할 시간 (기본 720시간 = 30일)
        """
        logger.info("========================================")
        logger.info("NASDAQ 100 Historical Data Load Started")
        logger.info("========================================")
        logger.info(f"Hours: {hours} ({hours/24:.1f} days)")
        
        # 1. CSV에서 종목 목록 읽기
        symbols = self._read_symbols()
        
        if not symbols:
            logger.error("No symbols found in CSV")
            return
        
        logger.info(f"Total symbols: {len(symbols)}")
        logger.info(f"Expected time: {len(symbols) * 2 / 60:.1f} minutes (2 sec per symbol)")
        logger.info("========================================")
        
        # 2. 시간 계산
        end_time = datetime.now(self.kst)
        start_time = end_time - timedelta(hours=hours)
        
        logger.info(f"Start: {start_time}")
        logger.info(f"End: {end_time}")
        
        # 3. 각 종목별 수집
        success_count = 0
        error_count = 0
        total_candles = 0
        
        start_timestamp = datetime.now()
        
        for idx, symbol in enumerate(symbols, 1):
            try:
                logger.info("")
                logger.info(f"[{idx}/{len(symbols)}] {symbol}")
                
                # 데이터 수집
                data_list = self._collect_symbol(symbol, start_time, end_time)
                
                if data_list:
                    logger.info(f"  ✅ {symbol}: {len(data_list)} candles collected")
                    success_count += 1
                    total_candles += len(data_list)
                else:
                    logger.warning(f"  ⚠️ {symbol}: No data")
                    error_count += 1
                
                # ========================================
                # API 부하 방지: 2초 대기 (마지막 종목 제외)
                # ========================================
                if idx < len(symbols):
                    logger.debug(f"  [WAIT] 2 seconds...")
                    time.sleep(2)  # ← 추가!
                
            except Exception as e:
                logger.error(f"  ❌ {symbol}: {e}")
                error_count += 1
                
                # 에러 발생해도 2초 대기
                if idx < len(symbols):
                    time.sleep(2)
        
        # 4. 결과 저장
        result = {
            'timestamp': datetime.now(self.kst).strftime('%Y-%m-%d %H:%M:%S'),
            'hours': hours,
            'total_symbols': len(symbols),
            'success_count': success_count,
            'error_count': error_count,
            'total_candles': total_candles
        }
        
        result_file = self.output_dir / f"nasdaq100_load_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(result_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        # 5. 통계 출력
        end_timestamp = datetime.now()
        elapsed_seconds = (end_timestamp - start_timestamp).total_seconds()
        
        logger.info("")
        logger.info("========================================")
        logger.info("NASDAQ 100 Historical Data Load Completed")
        logger.info("========================================")
        logger.info(f"Total: {len(symbols)}")
        logger.info(f"Success: {success_count}")
        logger.info(f"Errors: {error_count}")
        logger.info(f"Total candles: {total_candles}")
        logger.info(f"Elapsed time: {elapsed_seconds:.1f}s ({elapsed_seconds/60:.1f}m)")
        logger.info(f"Result saved: {result_file.name}")
        logger.info("========================================")
    
    def _read_symbols(self):
        """CSV에서 종목 목록 읽기"""
        symbols = []
        
        try:
            with open(self.csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    symbols.append(row['symbol'])
        except Exception as e:
            logger.error(f"Failed to read CSV: {e}")
        
        return symbols
    
    def _collect_symbol(self, symbol, start_time, end_time):
        """개별 종목 데이터 수집"""
        try:
            # UTC 변환
            start_time_utc = start_time.astimezone(self.utc)
            end_time_utc = end_time.astimezone(self.utc)
            
            # Yahoo Finance API 호출
            df = yf.download(
                symbol,
                start=start_time_utc,
                end=end_time_utc,
                interval='1m',
                progress=False,
                auto_adjust=True
            )
            
            if df.empty:
                return []
            
            # 데이터 변환
            data_list = []
            
            for timestamp, row in df.iterrows():
                try:
                    # UTC → KST
                    if timestamp.tz is None:
                        timestamp = timestamp.tz_localize(self.utc)
                    
                    timestamp_kst = timestamp.tz_convert(self.kst)
                    
                    # OHLCV 추출
                    def safe_extract(column_name):
                        try:
                            if isinstance(row[column_name], (int, float)):
                                return float(row[column_name])
                            else:
                                return float(row[column_name].iloc[0])
                        except:
                            return 0.0
                    
                    open_price = safe_extract('Open')
                    high_price = safe_extract('High')
                    low_price = safe_extract('Low')
                    close_price = safe_extract('Close')
                    
                    try:
                        if isinstance(row['Volume'], (int, float)):
                            volume = int(row['Volume'])
                        else:
                            volume = int(row['Volume'].iloc[0])
                    except:
                        volume = 0
                    
                    data_list.append({
                        'symbol': symbol,
                        'timestamp': timestamp_kst.strftime('%Y-%m-%d %H:%M:%S'),
                        'open': str(open_price),
                        'high': str(high_price),
                        'low': str(low_price),
                        'close': str(close_price),
                        'volume': volume
                    })
                    
                except Exception as e:
                    logger.error(f"Failed to process row: {e}")
                    continue
            
            return data_list
            
        except Exception as e:
            logger.error(f"Error collecting {symbol}: {e}")
            return []


# ========================================
# 메인 실행
# ========================================
if __name__ == "__main__":
    loader = Nasdaq100Loader()
    
    # 기본 30일 (720시간)
    loader.load_all(hours=720)