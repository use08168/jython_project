"""
========================================
JSON 파일 생성 모듈 - FileDataCollector 연동
========================================

목적:
- Python이 수집한 주식 데이터를 JSON 파일로 저장
- FileDataCollector.java가 이 파일을 폴링하여 처리
- 에러 처리 강화 (로깅)
- 타임스탬프 형식 통일 (초 포함 필수)

작성자: The Salty Spitoon Team
작성일: 2025-12-24 (타임스탬프 형식 수정)
"""

import json
from pathlib import Path
from datetime import datetime
import pytz
import logging

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class WebSocketPublisher:
    """
    JSON 파일 생성기
    
    역할:
    - 수집된 주식 데이터를 메모리에 저장
    - 전체 수집 완료 후 JSON 파일로 저장
    - FileDataCollector가 이 파일을 폴링
    """
    
    def __init__(self):
        """
        초기화
        
        설정:
        - 출력 디렉토리: python/output/
        - 파일명: latest_data.json
        - 전체 데이터 저장용 딕셔너리 초기화
        """
        # JSON 파일 경로
        self.output_dir = Path("python/output")
        self.output_file = self.output_dir / "latest_data.json"
        
        # 디렉토리 생성 (없으면)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # 전체 데이터 저장 (메모리)
        self.all_data = {}
        
        # 통계
        self.success_count = 0
        self.error_count = 0
        
        # 타임존 (KST)
        self.kst = pytz.timezone('Asia/Seoul')
        
        logger.info(f"WebSocketPublisher initialized: {self.output_file}")
    
    def publish(self, symbol, data):
        """
        종목 데이터를 메모리에 저장
        
        동작:
        1. 데이터 유효성 확인
        2. all_data 딕셔너리에 추가
        3. 숫자를 문자열로 변환 (BigDecimal 호환)
        4. 타임스탬프 형식 통일 (초 포함)
        
        Args:
            symbol (str): 종목 코드 (예: AAPL, GOOGL)
            data (dict): OHLCV 데이터 또는 에러 정보
        
        Returns:
            bool: 성공 시 True, 실패 시 False
        """
        try:
            # ========================================
            # 1. 에러 체크
            # ========================================
            if 'error' in data:
                logger.warning(f"[{symbol}] Skipped - {data['error']}: {data.get('reason', 'Unknown')}")
                self.error_count += 1
                return False
            
            # ========================================
            # 2. 필수 필드 체크
            # ========================================
            required_fields = ['timestamp', 'open', 'high', 'low', 'close', 'volume']
            
            for field in required_fields:
                if field not in data:
                    logger.error(f"[{symbol}] Missing field: {field}")
                    self.error_count += 1
                    return False
            
            # ========================================
            # 3. 타임스탬프 형식 통일 (초 포함 필수)
            # ========================================
            timestamp = self._normalize_timestamp(data['timestamp'])
            
            # ========================================
            # 4. 메모리에 저장
            # ========================================
            # BigDecimal 호환을 위해 숫자 → 문자열 변환
            self.all_data[symbol] = {
                'timestamp': timestamp,         # 정규화된 타임스탬프
                'open': str(data['open']),      # BigDecimal 호환
                'high': str(data['high']),
                'low': str(data['low']),
                'close': str(data['close']),
                'volume': data['volume']        # Long 타입은 그대로
            }
            
            self.success_count += 1
            logger.debug(f"[{symbol}] Stored: ${data['close']} @ {timestamp}")
            
            return True
            
        except Exception as e:
            logger.error(f"[{symbol}] Failed to store: {e}")
            import traceback
            traceback.print_exc()
            self.error_count += 1
            return False
    
    def _normalize_timestamp(self, timestamp):
        """
        타임스탬프 형식 정규화 (초 포함 보장)
        
        지원 형식:
        - datetime 객체 → "YYYY-MM-DD HH:MM:SS"
        - "YYYY-MM-DD HH:MM:SS" (19자) → 그대로 반환
        - "YYYY-MM-DD HH:MM" (16자) → ":00" 추가
        
        Args:
            timestamp: datetime 객체 또는 문자열
        
        Returns:
            str: "YYYY-MM-DD HH:MM:SS" 형식 문자열
        """
        try:
            # datetime 객체면 문자열로 변환
            if isinstance(timestamp, datetime):
                return timestamp.strftime('%Y-%m-%d %H:%M:%S')
            
            # 문자열 처리
            if isinstance(timestamp, str):
                timestamp = timestamp.strip()
                
                # 이미 초 포함 (19자): "2025-12-24 00:13:56"
                if len(timestamp) == 19:
                    return timestamp
                
                # 초 없음 (16자): "2025-12-24 00:13" → ":00" 추가
                if len(timestamp) == 16:
                    return timestamp + ':00'
                
                # ISO 형식: "2025-12-24T00:13:56" → 공백으로 변경
                if 'T' in timestamp:
                    return timestamp.replace('T', ' ')[:19]
            
            # 변환 실패
            logger.error(f"Unknown timestamp format: {timestamp}")
            return str(timestamp)
            
        except Exception as e:
            logger.error(f"Failed to normalize timestamp: {timestamp}, error: {e}")
            return str(timestamp)
    
    def save_all(self):
        """
        전체 종목 데이터를 JSON 파일로 저장
        
        동작:
        1. all_data가 비어있으면 스킵
        2. 현재 시각을 timestamp로 추가 (초 포함)
        3. JSON 파일로 저장
        4. 통계 로깅
        5. 메모리 초기화
        
        JSON 구조:
        {
          "timestamp": "2025-12-24 00:13:56",  // 파일 생성 시각 (초 포함)
          "data": {                             // 종목별 데이터
            "AAPL": { 
              "timestamp": "2025-12-24 00:13:00",  // 종목 데이터 시각 (초 포함)
              "open": "271.10",
              "high": "271.10",
              "low": "271.10",
              "close": "271.10",
              "volume": 0
            },
            "GOOGL": { ... },
            ...
          }
        }
        
        Returns:
            bool: 성공 시 True, 실패 시 False
        """
        try:
            # ========================================
            # 1. 데이터 없음 체크
            # ========================================
            if not self.all_data:
                logger.warning("No data to save (all collections failed)")
                return False
            
            # ========================================
            # 2. 현재 시각 (KST, 초 포함)
            # ========================================
            now_kst = datetime.now(self.kst)
            
            # ========================================
            # 3. JSON 구조 생성
            # ========================================
            output = {
                'timestamp': now_kst.strftime('%Y-%m-%d %H:%M:%S'),  # 초 포함!
                'data': self.all_data
            }
            
            # ========================================
            # 4. JSON 파일 저장
            # ========================================
            with open(self.output_file, 'w', encoding='utf-8') as f:
                json.dump(output, f, indent=2, ensure_ascii=False)
            
            # ========================================
            # 5. 통계 로깅
            # ========================================
            logger.info(f"[SAVE] JSON file saved: {self.output_file}")
            logger.info(f"[STATS] Success: {self.success_count}, Errors: {self.error_count}")
            logger.info(f"[STATS] Total symbols in file: {len(self.all_data)}")
            
            # ========================================
            # 6. 메모리 초기화 (다음 사이클 준비)
            # ========================================
            self.all_data = {}
            self.success_count = 0
            self.error_count = 0
            
            return True
            
        except Exception as e:
            logger.error(f"[ERROR] Failed to save JSON: {e}")
            import traceback
            traceback.print_exc()
            return False


# ========================================
# 테스트 코드
# ========================================
if __name__ == "__main__":
    print("="*60)
    print("WebSocketPublisher - Test (Timestamp Fix)")
    print("="*60)
    
    # 테스트 데이터 (다양한 타임스탬프 형식)
    test_data = [
        {
            'symbol': 'AAPL',
            'timestamp': '2025-12-24 00:13:56',  # 초 포함 (19자) ✅
            'open': 273.50,
            'high': 274.20,
            'low': 273.30,
            'close': 273.80,
            'volume': 1234567
        },
        {
            'symbol': 'GOOGL',
            'timestamp': '2025-12-24 00:13',     # 초 없음 (16자) → ":00" 추가
            'open': 182.10,
            'high': 182.50,
            'low': 181.90,
            'close': 182.35,
            'volume': 987654
        },
        {
            'symbol': 'MSFT',
            'timestamp': datetime.now(),         # datetime 객체 → 변환
            'open': 425.00,
            'high': 426.50,
            'low': 424.80,
            'close': 426.20,
            'volume': 555555
        },
        {
            'symbol': 'INVALID',
            'error': 'No data available',
            'reason': 'Market closed'
        }
    ]
    
    # Publisher 생성
    publisher = WebSocketPublisher()
    
    # 데이터 저장
    print("\n[TEST] Publishing test data...")
    for data in test_data:
        symbol = data['symbol']
        result = publisher.publish(symbol, data)
        if result:
            stored_timestamp = publisher.all_data[symbol]['timestamp']
            print(f"  ✅ {symbol}: {stored_timestamp} (length: {len(stored_timestamp)})")
        else:
            print(f"  ❌ {symbol}: Failed")
    
    # JSON 파일 생성
    print("\n[TEST] Saving to JSON...")
    if publisher.save_all():
        print("\n✅ Test passed!")
        print(f"📄 Check file: {publisher.output_file}")
        
        # 파일 내용 확인
        print("\n[TEST] File contents:")
        with open(publisher.output_file, 'r', encoding='utf-8') as f:
            content = json.load(f)
            print(f"  File timestamp: {content['timestamp']} (length: {len(content['timestamp'])})")
            for symbol, data in content['data'].items():
                print(f"  {symbol} timestamp: {data['timestamp']} (length: {len(data['timestamp'])})")
    else:
        print("\n❌ Test failed!")
    
    print("="*60)