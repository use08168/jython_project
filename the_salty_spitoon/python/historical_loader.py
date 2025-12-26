"""
========================================
Historical Data Loader - 과거 데이터 수집
========================================

목적:
- Yahoo Finance API를 통한 과거 1분봉 데이터 수집
- Request JSON 기반 작동
- Result JSON 생성 (Java가 읽음)

업데이트:
- Phase 2 (2025-12-23): start_time, end_time 파라미터 추가
- Phase 3 (2025-12-26): check_latest 모드 추가

작성자: The Salty Spitoon Team
작성일: 2025-12-26
"""

import yfinance as yf
import json
import sys
import pytz
from datetime import datetime, timedelta
from pathlib import Path
import logging

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class HistoricalDataLoader:
    """
    과거 데이터 수집기
    
    역할:
    - Request JSON 읽기
    - Yahoo Finance에서 과거 데이터 수집
    - Result JSON 생성
    """
    
    def __init__(self):
        """
        초기화
        """
        self.kst = pytz.timezone('Asia/Seoul')
        self.utc = pytz.UTC
    
    def load_from_request(self, request_file_path):
        """
        Request JSON 파일을 읽고 데이터 수집
        
        Request JSON 형식 (기존):
        {
          "symbol": "AAPL",
          "hours": 720
        }
        
        Request JSON 형식 (신규 - Phase 2):
        {
          "symbol": "AAPL",
          "start_time": "2025-12-23 06:00:00",  // KST
          "end_time": "2025-12-23 17:30:00"      // KST
        }
        
        Request JSON 형식 (최신 시각 조회 - Phase 3):
        {
          "symbol": "AAPL",
          "mode": "check_latest"
        }
        
        호환성:
        - mode=check_latest: 최신 데이터 시각만 조회
        - start_time, end_time 있으면 신규 방식
        - hours 있으면 기존 방식 (레거시)
        
        Args:
            request_file_path (str): Request JSON 파일 경로
        
        Returns:
            dict: Result JSON
        """
        try:
            # ========================================
            # 1. Request JSON 읽기
            # ========================================
            logger.info("========================================")
            logger.info("Historical Data Loader Started")
            logger.info("========================================")
            
            request_file = Path(request_file_path)
            
            if not request_file.exists():
                raise FileNotFoundError(f"Request file not found: {request_file_path}")
            
            with open(request_file, 'r', encoding='utf-8') as f:
                request = json.load(f)
            
            logger.info(f"Request file: {request_file.name}")
            logger.info(f"Request content: {request}")
            
            # ========================================
            # 2. 파라미터 추출
            # ========================================
            symbol = request.get('symbol')
            
            if not symbol:
                raise ValueError("Missing 'symbol' in request")
            
            # ========================================
            # 3. 수집 방식 결정
            # ========================================
            
            # 🆕 최신 시각 조회 모드
            if request.get('mode') == 'check_latest':
                logger.info("Mode: Check latest timestamp")
                latest_timestamp = self.get_latest_timestamp(symbol)
                
                result = {
                    'symbol': symbol,
                    'status': 'success',
                    'mode': 'check_latest',
                    'latest_timestamp': latest_timestamp,
                    'data': []
                }
            
            # 신규 방식: start_time, end_time 사용
            elif 'start_time' in request and request['start_time'] is not None:
                logger.info("Using new method: start_time + end_time")
                result = self._collect_by_time_range(
                    symbol=symbol,
                    start_time_str=request['start_time'],
                    end_time_str=request['end_time']
                )
            
            # 레거시 방식: hours 사용
            elif 'hours' in request:
                logger.info("Using legacy method: hours")
                hours = request['hours']
                result = self._collect_by_hours(symbol, hours)
            
            else:
                raise ValueError("Invalid request: missing 'mode', 'start_time'/'end_time' or 'hours'")
            
            # ========================================
            # 4. Result JSON 저장
            # ========================================
            result_file_name = request_file.stem.replace('request_', 'result_') + '.json'
            result_file_path = request_file.parent.parent / 'results' / result_file_name
            
            # results 디렉토리 생성
            result_file_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(result_file_path, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Result saved: {result_file_path.name}")
            logger.info("========================================")
            logger.info("Historical Data Loader Completed")
            logger.info("========================================")
            
            return result
            
        except Exception as e:
            logger.error(f"Error loading historical data: {e}")
            import traceback
            traceback.print_exc()
            
            # 에러 결과 반환
            error_result = {
                'symbol': symbol if 'symbol' in locals() else 'UNKNOWN',
                'status': 'error',
                'error': str(e),
                'data': []
            }
            
            # 에러 결과도 저장
            try:
                result_file_name = request_file.stem.replace('request_', 'result_') + '.json'
                result_file_path = request_file.parent.parent / 'results' / result_file_name
                result_file_path.parent.mkdir(parents=True, exist_ok=True)
                
                with open(result_file_path, 'w', encoding='utf-8') as f:
                    json.dump(error_result, f, indent=2, ensure_ascii=False)
            except:
                pass
            
            return error_result
    
    def get_latest_timestamp(self, symbol):
        """
        Yahoo Finance에서 특정 종목의 최신 데이터 시각 조회
        
        Args:
            symbol (str): 종목 코드
        
        Returns:
            str: 최신 데이터 시각 (KST, "2025-12-26 05:00:00") 또는 None
        """
        logger.info(f"[{symbol}] Checking latest available timestamp from Yahoo Finance")
        
        try:
            # 최근 7일 데이터 조회 (최신 1개만 필요)
            end_time = datetime.now(self.kst)
            start_time = end_time - timedelta(days=7)
            
            start_time_utc = start_time.astimezone(self.utc)
            end_time_utc = end_time.astimezone(self.utc)
            
            df = yf.download(
                symbol,
                start=start_time_utc,
                end=end_time_utc,
                interval='1m',
                progress=False,
                auto_adjust=True
            )
            
            if df.empty:
                logger.warning(f"[{symbol}] No data available from Yahoo Finance")
                return None
            
            # 가장 최신 데이터의 timestamp
            latest_timestamp = df.index[-1]
            
            if latest_timestamp.tz is None:
                latest_timestamp = latest_timestamp.tz_localize(self.utc)
            
            latest_timestamp_kst = latest_timestamp.tz_convert(self.kst)
            latest_str = latest_timestamp_kst.strftime('%Y-%m-%d %H:%M:%S')
            
            logger.info(f"[{symbol}] Latest available: {latest_str}")
            
            return latest_str
            
        except Exception as e:
            logger.error(f"[{symbol}] Error checking latest timestamp: {e}")
            return None
    
    def _collect_by_time_range(self, symbol, start_time_str, end_time_str):
        """
        특정 시간 범위의 데이터 수집 (신규 방식 - Phase 2)
        
        Args:
            symbol (str): 종목 코드
            start_time_str (str): 시작 시각 (KST, "2025-12-23 06:00:00")
            end_time_str (str): 종료 시각 (KST, "2025-12-23 17:30:00")
        
        Returns:
            dict: Result JSON
        """
        logger.info(f"[{symbol}] Collecting data from {start_time_str} to {end_time_str}")
        
        try:
            # ========================================
            # 1. 시각 파싱 (KST → UTC)
            # ========================================
            
            # KST 문자열 → datetime 객체
            start_dt_kst = datetime.strptime(start_time_str, '%Y-%m-%d %H:%M:%S')
            end_dt_kst = datetime.strptime(end_time_str, '%Y-%m-%d %H:%M:%S')
            
            # KST 타임존 설정
            start_dt_kst = self.kst.localize(start_dt_kst)
            end_dt_kst = self.kst.localize(end_dt_kst)
            
            # UTC 변환 (Yahoo Finance는 UTC 사용)
            start_dt_utc = start_dt_kst.astimezone(self.utc)
            end_dt_utc = end_dt_kst.astimezone(self.utc)
            
            logger.info(f"[{symbol}] Start (UTC): {start_dt_utc}")
            logger.info(f"[{symbol}] End (UTC): {end_dt_utc}")
            
            # ========================================
            # 2. Yahoo Finance API 호출
            # ========================================
            
            # yfinance는 start/end를 받음
            df = yf.download(
                symbol,
                start=start_dt_utc,
                end=end_dt_utc,
                interval='1m',
                progress=False,
                auto_adjust=True
            )
            
            # ========================================
            # 3. 데이터 확인
            # ========================================
            if df.empty:
                logger.warning(f"[{symbol}] No data available for the specified range")
                return {
                    'symbol': symbol,
                    'status': 'success',
                    'message': 'No data available for the specified range',
                    'count': 0,
                    'data': []
                }
            
            logger.info(f"[{symbol}] Downloaded {len(df)} candles")
            
            # ========================================
            # 4. 데이터 변환 (DataFrame → JSON)
            # ========================================
            data_list = []
            
            for timestamp, row in df.iterrows():
                try:
                    # UTC → KST 변환
                    if timestamp.tz is None:
                        timestamp = timestamp.tz_localize(self.utc)
                    
                    timestamp_kst = timestamp.tz_convert(self.kst)
                    
                    # OHLCV 추출
                    def safe_extract(column_name):
                        """안전한 데이터 추출"""
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
                    
                    # 데이터 추가
                    data_list.append({
                        'timestamp': timestamp_kst.strftime('%Y-%m-%d %H:%M:%S'),
                        'open': str(open_price),      # BigDecimal 호환
                        'high': str(high_price),
                        'low': str(low_price),
                        'close': str(close_price),
                        'volume': volume
                    })
                    
                except Exception as e:
                    logger.error(f"[{symbol}] Failed to process row: {e}")
                    continue
            
            # ========================================
            # 5. 결과 반환
            # ========================================
            logger.info(f"[{symbol}] Processed {len(data_list)} candles")
            
            return {
                'symbol': symbol,
                'status': 'success',
                'message': f'Collected {len(data_list)} candles',
                'count': len(data_list),
                'start_time': start_time_str,
                'end_time': end_time_str,
                'data': data_list
            }
            
        except Exception as e:
            logger.error(f"[{symbol}] Error collecting data: {e}")
            import traceback
            traceback.print_exc()
            
            return {
                'symbol': symbol,
                'status': 'error',
                'error': str(e),
                'data': []
            }
    
    def _collect_by_hours(self, symbol, hours):
        """
        지정된 시간만큼 과거 데이터 수집 (레거시 방식)
        
        Args:
            symbol (str): 종목 코드
            hours (int): 수집할 시간 (시간 단위)
        
        Returns:
            dict: Result JSON
        """
        logger.info(f"[{symbol}] Collecting last {hours} hours of data")
        
        try:
            # ========================================
            # 1. 시간 계산
            # ========================================
            end_time = datetime.now(self.kst)
            start_time = end_time - timedelta(hours=hours)
            
            logger.info(f"[{symbol}] Start: {start_time}")
            logger.info(f"[{symbol}] End: {end_time}")
            
            # ========================================
            # 2. UTC 변환
            # ========================================
            start_time_utc = start_time.astimezone(self.utc)
            end_time_utc = end_time.astimezone(self.utc)
            
            # ========================================
            # 3. Yahoo Finance API 호출
            # ========================================
            df = yf.download(
                symbol,
                start=start_time_utc,
                end=end_time_utc,
                interval='1m',
                progress=False,
                auto_adjust=True
            )
            
            # ========================================
            # 4. 데이터 확인
            # ========================================
            if df.empty:
                logger.warning(f"[{symbol}] No data available")
                return {
                    'symbol': symbol,
                    'status': 'success',
                    'message': 'No data available',
                    'count': 0,
                    'data': []
                }
            
            logger.info(f"[{symbol}] Downloaded {len(df)} candles")
            
            # ========================================
            # 5. 데이터 변환
            # ========================================
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
                        'timestamp': timestamp_kst.strftime('%Y-%m-%d %H:%M:%S'),
                        'open': str(open_price),
                        'high': str(high_price),
                        'low': str(low_price),
                        'close': str(close_price),
                        'volume': volume
                    })
                    
                except Exception as e:
                    logger.error(f"[{symbol}] Failed to process row: {e}")
                    continue
            
            # ========================================
            # 6. 결과 반환
            # ========================================
            logger.info(f"[{symbol}] Processed {len(data_list)} candles")
            
            return {
                'symbol': symbol,
                'status': 'success',
                'message': f'Collected {len(data_list)} candles',
                'count': len(data_list),
                'hours': hours,
                'data': data_list
            }
            
        except Exception as e:
            logger.error(f"[{symbol}] Error collecting data: {e}")
            import traceback
            traceback.print_exc()
            
            return {
                'symbol': symbol,
                'status': 'error',
                'error': str(e),
                'data': []
            }


# ========================================
# 메인 실행
# ========================================
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python historical_loader.py <request_file_path>")
        sys.exit(1)
    
    request_file_path = sys.argv[1]
    
    loader = HistoricalDataLoader()
    result = loader.load_from_request(request_file_path)
    
    # 결과 출력
    print("\n" + "="*60)
    print("Historical Data Loader Result")
    print("="*60)
    print(f"Symbol: {result.get('symbol')}")
    print(f"Status: {result.get('status')}")
    
    if result.get('mode') == 'check_latest':
        print(f"Latest Timestamp: {result.get('latest_timestamp')}")
    else:
        print(f"Message: {result.get('message')}")
        print(f"Count: {result.get('count', 0)}")
    
    if result.get('status') == 'error':
        print(f"Error: {result.get('error')}")
    
    print("="*60)