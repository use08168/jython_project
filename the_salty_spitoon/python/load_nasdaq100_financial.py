"""
========================================
NASDAQ 100 재무 데이터 수집기 (Rate Limit 최적화)
========================================

목적:
- NASDAQ 100 전체 종목(101개)의 재무 데이터 수집
- yfinance API Rate Limit 회피
- 안정적인 대량 데이터 수집

Rate Limit 전략:
- 종목당 2초 대기 (기본값)
- 10종목마다 5초 추가 대기
- 에러 발생 시 10초 대기 후 재시도

예상 실행 시간:
- 101개 종목 × 2초 = 202초 (약 3분 30초)
- 추가 대기 시간 포함: 약 5분

작성자: The Salty Spitoon Team
작성일: 2025-12-21
수정일: 2025-12-21 (Rate Limit 강화)
"""

import yfinance as yf
import json
import time
import csv
from pathlib import Path
from datetime import datetime, timedelta
import pandas as pd

# ========================================
# 설정
# ========================================
BASE_DIR = Path(__file__).parent.parent
CSV_FILE = BASE_DIR / "python" / "nasdaq100_tickers.csv"
RESULTS_DIR = BASE_DIR / "python" / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Rate Limit 설정
WAIT_BETWEEN_SYMBOLS = 2  # 종목 간 대기 시간 (초)
WAIT_EVERY_N_SYMBOLS = 10  # N개 종목마다 추가 대기
WAIT_ADDITIONAL = 5  # 추가 대기 시간 (초)
WAIT_ON_ERROR = 10  # 에러 발생 시 대기 시간 (초)

# 결과 파일명 (타임스탬프)
TIMESTAMP = datetime.now().strftime('%Y%m%d_%H%M%S')
RESULT_FILE = RESULTS_DIR / f"financial_data_{TIMESTAMP}.json"


def load_tickers():
    """
    CSV에서 NASDAQ 100 종목 목록 로드
    
    Returns:
        list: [{"symbol": "AAPL", "name": "Apple Inc."}, ...]
    """
    print(f"[INFO] Reading CSV: {CSV_FILE}")
    
    tickers = []
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            tickers.append({
                'symbol': row['symbol'],
                'name': row['name']
            })
    
    print(f"[OK] Loaded {len(tickers)} tickers")
    return tickers


def safe_get(data, key, default=None):
    """
    딕셔너리에서 안전하게 값 가져오기
    
    Args:
        data: 딕셔너리
        key: 키
        default: 기본값
    
    Returns:
        값 또는 기본값
    """
    try:
        value = data.get(key)
        if value is None or (isinstance(value, float) and pd.isna(value)):
            return default
        return value
    except:
        return default


def convert_to_serializable(obj):
    """
    pandas/numpy 타입을 JSON 직렬화 가능한 타입으로 변환
    
    Args:
        obj: 변환할 객체
    
    Returns:
        JSON 직렬화 가능한 객체
    """
    if pd.isna(obj):
        return None
    if isinstance(obj, (pd.Timestamp, datetime)):
        return obj.strftime('%Y-%m-%d')
    if isinstance(obj, (int, float)):
        return float(obj) if not pd.isna(obj) else None
    return obj


def collect_financial_data(symbol, name):
    """
    개별 종목의 재무 데이터 수집
    
    Args:
        symbol (str): 종목 심볼
        name (str): 회사명
    
    Returns:
        dict: 재무 데이터 전체
    """
    print(f"\n{'='*60}")
    print(f"[{symbol}] {name}")
    print('='*60)
    
    result = {
        'symbol': symbol,
        'name': name,
        'success': False,
        'error': None,
        'income_statement': {'quarterly': [], 'yearly': []},
        'balance_sheet': {'quarterly': [], 'yearly': []},
        'cashflow': {'quarterly': [], 'yearly': []},
        'metrics': {},
        'dividends': [],
        'company_info': {}
    }
    
    try:
        # Ticker 객체 생성
        ticker = yf.Ticker(symbol)
        
        # ========================================
        # 1. 재무제표 (Income Statement)
        # ========================================
        print("[1/6] Collecting Income Statement...")
        
        # 분기별
        quarterly_financials = ticker.quarterly_financials
        if not quarterly_financials.empty:
            for date_col in quarterly_financials.columns[:12]:  # 최근 12분기
                data = {}
                for idx in quarterly_financials.index:
                    key = idx.lower().replace(' ', '_')
                    value = quarterly_financials.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['income_statement']['quarterly'].append(data)
        
        # 연간
        yearly_financials = ticker.financials
        if not yearly_financials.empty:
            for date_col in yearly_financials.columns[:4]:  # 최근 4년
                data = {}
                for idx in yearly_financials.index:
                    key = idx.lower().replace(' ', '_')
                    value = yearly_financials.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['income_statement']['yearly'].append(data)
        
        print(f"  Quarterly: {len(result['income_statement']['quarterly'])}, Yearly: {len(result['income_statement']['yearly'])}")
        
        # ========================================
        # 2. 대차대조표 (Balance Sheet)
        # ========================================
        print("[2/6] Collecting Balance Sheet...")
        
        # 분기별
        quarterly_balance = ticker.quarterly_balance_sheet
        if not quarterly_balance.empty:
            for date_col in quarterly_balance.columns[:12]:
                data = {}
                for idx in quarterly_balance.index:
                    key = idx.lower().replace(' ', '_')
                    value = quarterly_balance.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['balance_sheet']['quarterly'].append(data)
        
        # 연간
        yearly_balance = ticker.balance_sheet
        if not yearly_balance.empty:
            for date_col in yearly_balance.columns[:4]:
                data = {}
                for idx in yearly_balance.index:
                    key = idx.lower().replace(' ', '_')
                    value = yearly_balance.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['balance_sheet']['yearly'].append(data)
        
        print(f"  Quarterly: {len(result['balance_sheet']['quarterly'])}, Yearly: {len(result['balance_sheet']['yearly'])}")
        
        # ========================================
        # 3. 현금흐름표 (Cash Flow Statement)
        # ========================================
        print("[3/6] Collecting Cash Flow...")
        
        # 분기별
        quarterly_cashflow = ticker.quarterly_cashflow
        if not quarterly_cashflow.empty:
            for date_col in quarterly_cashflow.columns[:12]:
                data = {}
                for idx in quarterly_cashflow.index:
                    key = idx.lower().replace(' ', '_')
                    value = quarterly_cashflow.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['cashflow']['quarterly'].append(data)
        
        # 연간
        yearly_cashflow = ticker.cashflow
        if not yearly_cashflow.empty:
            for date_col in yearly_cashflow.columns[:4]:
                data = {}
                for idx in yearly_cashflow.index:
                    key = idx.lower().replace(' ', '_')
                    value = yearly_cashflow.loc[idx, date_col]
                    data[key] = convert_to_serializable(value)
                
                data['fiscal_date'] = convert_to_serializable(date_col)
                result['cashflow']['yearly'].append(data)
        
        print(f"  Quarterly: {len(result['cashflow']['quarterly'])}, Yearly: {len(result['cashflow']['yearly'])}")
        
        # ========================================
        # 4. 재무 지표 (Metrics from info)
        # ========================================
        print("[4/6] Collecting Metrics...")
        
        info = ticker.info
        
        result['metrics'] = {
            # 수익성
            'profit_margins': safe_get(info, 'profitMargins'),
            'operating_margins': safe_get(info, 'operatingMargins'),
            'gross_margins': safe_get(info, 'grossMargins'),
            'ebitda_margins': safe_get(info, 'ebitdaMargins'),
            'return_on_equity': safe_get(info, 'returnOnEquity'),
            'return_on_assets': safe_get(info, 'returnOnAssets'),
            
            # 성장성
            'revenue_growth': safe_get(info, 'revenueGrowth'),
            'earnings_growth': safe_get(info, 'earningsGrowth'),
            'earnings_quarterly_growth': safe_get(info, 'earningsQuarterlyGrowth'),
            
            # 재무 건전성
            'current_ratio': safe_get(info, 'currentRatio'),
            'quick_ratio': safe_get(info, 'quickRatio'),
            'debt_to_equity': safe_get(info, 'debtToEquity'),
            'total_debt': safe_get(info, 'totalDebt'),
            'total_cash': safe_get(info, 'totalCash'),
            
            # 밸류에이션
            'trailing_pe': safe_get(info, 'trailingPE'),
            'forward_pe': safe_get(info, 'forwardPE'),
            'peg_ratio': safe_get(info, 'pegRatio'),
            'price_to_book': safe_get(info, 'priceToBook'),
            'price_to_sales_trailing_12_months': safe_get(info, 'priceToSalesTrailing12Months'),
            'enterprise_value': safe_get(info, 'enterpriseValue'),
            'enterprise_to_revenue': safe_get(info, 'enterpriseToRevenue'),
            'enterprise_to_ebitda': safe_get(info, 'enterpriseToEbitda'),
            
            # EPS
            'trailing_eps': safe_get(info, 'trailingEps'),
            'forward_eps': safe_get(info, 'forwardEps'),
            
            # 배당
            'dividend_rate': safe_get(info, 'dividendRate'),
            'dividend_yield': safe_get(info, 'dividendYield'),
            'payout_ratio': safe_get(info, 'payoutRatio'),
            
            # 시장
            'market_cap': safe_get(info, 'marketCap'),
            'shares_outstanding': safe_get(info, 'sharesOutstanding'),
            'float_shares': safe_get(info, 'floatShares'),
            'shares_short': safe_get(info, 'sharesShort'),
            'short_ratio': safe_get(info, 'shortRatio'),
            'beta': safe_get(info, 'beta'),
            
            # 52주
            'fifty_two_week_high': safe_get(info, 'fiftyTwoWeekHigh'),
            'fifty_two_week_low': safe_get(info, 'fiftyTwoWeekLow'),
            'fifty_day_average': safe_get(info, 'fiftyDayAverage'),
            'two_hundred_day_average': safe_get(info, 'twoHundredDayAverage')
        }
        
        print(f"  Metrics: {len([v for v in result['metrics'].values() if v is not None])} non-null values")
        
        # ========================================
        # 5. 배당금 (Dividends - 최근 5년)
        # ========================================
        print("[5/6] Collecting Dividends...")
        
        try:
            dividends = ticker.dividends
            if not dividends.empty:
                # 최근 5년 데이터만 필터링
                recent_dividends = dividends.tail(20)  # 단순하게 최근 20개만
                
                for date, amount in recent_dividends.items():
                    result['dividends'].append({
                        'payment_date': date.strftime('%Y-%m-%d'),
                        'dividend_amount': float(amount)
                    })
            
            print(f"  Dividends: {len(result['dividends'])}")
            
        except Exception as e:
            print(f"  [WARN] Dividend collection failed: {e}")
            # 에러 발생해도 계속 진행
        
        # ========================================
        # 6. 기업 정보 (Company Info)
        # ========================================
        print("[6/6] Collecting Company Info...")
        
        result['company_info'] = {
            'long_name': safe_get(info, 'longName'),
            'short_name': safe_get(info, 'shortName'),
            'sector': safe_get(info, 'sector'),
            'industry': safe_get(info, 'industry'),
            'industry_key': safe_get(info, 'industryKey'),
            'sector_key': safe_get(info, 'sectorKey'),
            'country': safe_get(info, 'country'),
            'city': safe_get(info, 'city'),
            'state': safe_get(info, 'state'),
            'address': safe_get(info, 'address1'),
            'zip_code': safe_get(info, 'zip'),
            'website': safe_get(info, 'website'),
            'phone': safe_get(info, 'phone'),
            'full_time_employees': safe_get(info, 'fullTimeEmployees'),
            'long_business_summary': safe_get(info, 'longBusinessSummary'),
            'market_cap': safe_get(info, 'marketCap'),
            'enterprise_value': safe_get(info, 'enterpriseValue')
        }
        
        print(f"  Company Info: {result['company_info']['long_name']}")
        
        # ========================================
        # 성공
        # ========================================
        result['success'] = True
        print(f"[OK] {symbol} collected successfully")
        
    except Exception as e:
        print(f"[ERROR] {symbol}: {e}")
        result['error'] = str(e)
    
    return result


def main():
    """
    메인 함수
    """
    print("="*60)
    print("NASDAQ 100 Financial Data Collector")
    print("="*60)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Output: {RESULT_FILE}")
    print(f"Rate Limit: {WAIT_BETWEEN_SYMBOLS}s between symbols")
    print(f"Additional Wait: {WAIT_ADDITIONAL}s every {WAIT_EVERY_N_SYMBOLS} symbols")
    print("="*60)
    
    # 종목 목록 로드
    tickers = load_tickers()
    
    # 결과 수집
    all_results = []
    success_count = 0
    failed_count = 0
    error_count = 0
    
    for i, ticker in enumerate(tickers, 1):
        symbol = ticker['symbol']
        name = ticker['name']
        
        print(f"\n[{i}/{len(tickers)}] Processing...")
        
        # 데이터 수집 (에러 재시도 로직)
        result = None
        retry_count = 0
        max_retries = 2
        
        while retry_count <= max_retries:
            try:
                result = collect_financial_data(symbol, name)
                break  # 성공 시 루프 종료
                
            except Exception as e:
                retry_count += 1
                error_count += 1
                
                if retry_count <= max_retries:
                    print(f"\n[ERROR] Attempt {retry_count} failed: {e}")
                    print(f"[RETRY] Waiting {WAIT_ON_ERROR}s before retry...")
                    time.sleep(WAIT_ON_ERROR)
                else:
                    print(f"\n[FAILED] Max retries reached for {symbol}")
                    result = {
                        'symbol': symbol,
                        'name': name,
                        'success': False,
                        'error': str(e),
                        'income_statement': {'quarterly': [], 'yearly': []},
                        'balance_sheet': {'quarterly': [], 'yearly': []},
                        'cashflow': {'quarterly': [], 'yearly': []},
                        'metrics': {},
                        'dividends': [],
                        'company_info': {}
                    }
        
        all_results.append(result)
        
        # 통계
        if result['success']:
            success_count += 1
        else:
            failed_count += 1
        
        # 진행률
        print(f"\n[PROGRESS] {i}/{len(tickers)} completed")
        print(f"[SUCCESS] {success_count} | [FAILED] {failed_count} | [ERRORS] {error_count}")
        
        # ========================================
        # Rate Limit 대기
        # ========================================
        if i < len(tickers):
            # 기본 대기
            print(f"\n[WAIT] {WAIT_BETWEEN_SYMBOLS} seconds before next symbol...")
            time.sleep(WAIT_BETWEEN_SYMBOLS)
            
            # 추가 대기 (10종목마다)
            if i % WAIT_EVERY_N_SYMBOLS == 0:
                print(f"[WAIT] Additional {WAIT_ADDITIONAL}s (every {WAIT_EVERY_N_SYMBOLS} symbols)...")
                time.sleep(WAIT_ADDITIONAL)
    
    # 결과 저장
    summary = {
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'total': len(tickers),
        'success': success_count,
        'failed': failed_count,
        'errors': error_count,
        'data': all_results
    }
    
    with open(RESULT_FILE, 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)
    
    print("\n" + "="*60)
    print("Collection Complete!")
    print("="*60)
    print(f"Total: {len(tickers)}")
    print(f"Success: {success_count}")
    print(f"Failed: {failed_count}")
    print(f"Total Errors: {error_count}")
    print(f"Result saved: {RESULT_FILE}")
    print("="*60)
    
    # 실패 종목 출력
    if failed_count > 0:
        print(f"\n[FAILED SYMBOLS]")
        for result in all_results:
            if not result['success']:
                print(f"  - {result['symbol']}: {result['error']}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[INTERRUPTED] Stopped by user")
    except Exception as e:
        print(f"\n\n[ERROR] {e}")
        import traceback
        traceback.print_exc()
