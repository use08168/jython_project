"""
========================================
실시간 주식 데이터 수집 스케줄러 (1분 간격)
========================================

전략:
- 매 분 00초에 정확히 실행
- 이전 분의 완성된 봉 수집
- 무한 루프

작성자: The Salty Spitoon Team
최종 수정: 2025-12-24
"""

import time
import logging
from datetime import datetime
import pytz
from stock_collector import collect_all_stocks

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# KST 타임존
kst = pytz.timezone('Asia/Seoul')


def wait_for_next_minute():
    """
    다음 분 00초까지 대기
    
    예:
    - 현재: 23:30:45 → 23:31:00까지 15초 대기
    - 현재: 23:30:05 → 23:31:00까지 55초 대기
    """
    now = datetime.now()
    current_second = now.second
    
    # 다음 분 00초까지 남은 시간
    wait_seconds = 60 - current_second
    
    if wait_seconds < 60:
        logger.debug(f"[WAIT] Waiting {wait_seconds}s for next minute")
        time.sleep(wait_seconds)


def main():
    """
    메인 루프
    
    동작:
    1. 첫 실행 전 다음 분 00초까지 대기
    2. 정각에 데이터 수집
    3. 다음 분 00초까지 대기
    4. 2-3 반복
    """
    logger.info("="*60)
    logger.info("Stock Data Collector Started (1분 간격)")
    logger.info("="*60)
    logger.info("")
    
    # ========================================
    # 첫 실행 전 다음 분 00초까지 대기
    # ========================================
    now = datetime.now(kst)
    logger.info(f"[START] Current time: {now.strftime('%Y-%m-%d %H:%M:%S KST')}")
    
    if now.second != 0:
        wait_seconds = 60 - now.second
        logger.info(f"[WAIT] Waiting {wait_seconds}s for first collection...")
        logger.info("")
        time.sleep(wait_seconds)
    
    # ========================================
    # 메인 루프
    # ========================================
    cycle_count = 0
    
    while True:
        try:
            cycle_count += 1
            
            # 현재 시각 (정각이어야 함)
            now = datetime.now(kst)
            logger.info("="*60)
            logger.info(f"[CYCLE #{cycle_count}] Starting at {now.strftime('%Y-%m-%d %H:%M:%S KST')}")
            logger.info("="*60)
            logger.info("")
            
            # 수집 시작
            start_time = time.time()
            
            # ========================================
            # 전체 종목 수집
            # ========================================
            success, errors = collect_all_stocks()
            
            # 수집 완료
            elapsed = time.time() - start_time
            
            # ========================================
            # 통계 로깅
            # ========================================
            logger.info("")
            logger.info("="*60)
            logger.info(f"[COMPLETE] Cycle #{cycle_count} finished")
            logger.info(f"[STATS] Success: {success}, Errors: {errors}")
            logger.info(f"[TIME] {elapsed:.1f}s ({elapsed/101:.2f}s per symbol)")
            logger.info("="*60)
            logger.info("")
            
            # ========================================
            # 다음 분 00초까지 대기
            # ========================================
            wait_for_next_minute()
            
        except KeyboardInterrupt:
            logger.info("")
            logger.info("="*60)
            logger.info("[STOP] Interrupted by user (Ctrl+C)")
            logger.info(f"[TOTAL] Completed {cycle_count} cycles")
            logger.info("="*60)
            break
            
        except Exception as e:
            logger.error(f"[ERROR] Unexpected error in cycle #{cycle_count}: {e}")
            import traceback
            traceback.print_exc()
            
            # 에러 발생 시 1분 대기 후 재시도
            logger.info("[RETRY] Waiting 60 seconds before retry...")
            logger.info("")
            time.sleep(60)


if __name__ == "__main__":
    main()