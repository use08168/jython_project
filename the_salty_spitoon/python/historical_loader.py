#!/usr/bin/env python3
"""
Historical Data Loader (Direct API Version)
- yfinance 대신 Yahoo Finance API 직접 호출
- 단일 종목의 과거 1분봉 데이터 수집

사용법:
    python historical_loader.py --symbol AAPL --days 3 --output result.json

@author The Salty Spitoon Team
@since 2025-12-26
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime

import requests
import pytz


def collect_historical_data(symbol: str, days: int) -> dict:
    """
    Yahoo Finance API에서 직접 과거 1분봉 데이터 수집
    
    Args:
        symbol: 종목 코드 (예: AAPL)
        days: 수집할 일수 (최대 7일 - Yahoo Finance 1분봉 제한)
    
    Returns:
        {
            "success": bool,
            "symbol": str,
            "candles": [...],
            "count": int,
            "message": str
        }
    """
    try:
        # Yahoo Finance 1분봉은 최근 7일까지만 지원
        days = min(days, 7)
        
        # Yahoo Finance API 직접 호출
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
        params = {
            "interval": "1m",
            "range": f"{days}d"
        }
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
        
        response = requests.get(url, params=params, headers=headers, timeout=30)
        
        if response.status_code != 200:
            return {
                "success": False,
                "symbol": symbol,
                "candles": [],
                "count": 0,
                "message": f"API Error: HTTP {response.status_code}"
            }
        
        data = response.json()
        
        # 응답 검증
        if "chart" not in data or "result" not in data["chart"]:
            return {
                "success": False,
                "symbol": symbol,
                "candles": [],
                "count": 0,
                "message": "Invalid API response"
            }
        
        result = data["chart"]["result"]
        if not result:
            return {
                "success": False,
                "symbol": symbol,
                "candles": [],
                "count": 0,
                "message": "No data returned from Yahoo Finance"
            }
        
        chart_data = result[0]
        
        # 타임스탬프와 가격 데이터 추출
        timestamps = chart_data.get("timestamp", [])
        indicators = chart_data.get("indicators", {})
        quote = indicators.get("quote", [{}])[0]
        
        opens = quote.get("open", [])
        highs = quote.get("high", [])
        lows = quote.get("low", [])
        closes = quote.get("close", [])
        volumes = quote.get("volume", [])
        
        if not timestamps or not closes:
            return {
                "success": False,
                "symbol": symbol,
                "candles": [],
                "count": 0,
                "message": "No price data in response"
            }
        
        # 캔들 데이터 생성
        candles = []
        ny_tz = pytz.timezone('America/New_York')
        
        for i, ts in enumerate(timestamps):
            if ts is None:
                continue
                
            # None 값 체크
            o = opens[i] if i < len(opens) else None
            h = highs[i] if i < len(highs) else None
            l = lows[i] if i < len(lows) else None
            c = closes[i] if i < len(closes) else None
            v = volumes[i] if i < len(volumes) else None
            
            if o is None or h is None or l is None or c is None:
                continue
            
            # 타임스탬프 변환 (UTC -> datetime)
            dt = datetime.fromtimestamp(ts, tz=pytz.UTC)
            # 뉴욕 시간으로 변환 후 tzinfo 제거
            dt_ny = dt.astimezone(ny_tz).replace(tzinfo=None)
            
            candle = {
                "symbol": symbol,
                "datetime": dt_ny.strftime('%Y-%m-%dT%H:%M:%S'),
                "open": round(float(o), 4),
                "high": round(float(h), 4),
                "low": round(float(l), 4),
                "close": round(float(c), 4),
                "volume": int(v) if v else 0
            }
            
            candles.append(candle)
        
        return {
            "success": True,
            "symbol": symbol,
            "candles": candles,
            "count": len(candles),
            "message": f"Successfully collected {len(candles)} candles"
        }
        
    except requests.exceptions.Timeout:
        return {
            "success": False,
            "symbol": symbol,
            "candles": [],
            "count": 0,
            "message": "API request timeout"
        }
    except Exception as e:
        return {
            "success": False,
            "symbol": symbol,
            "candles": [],
            "count": 0,
            "message": f"Error: {str(e)}"
        }


def main():
    parser = argparse.ArgumentParser(description='Historical Data Loader for The Salty Spitoon')
    parser.add_argument('--symbol', required=True, help='Stock symbol (e.g., AAPL)')
    parser.add_argument('--days', type=int, default=1, help='Number of days to collect (max 7)')
    parser.add_argument('--output', required=True, help='Output JSON file path')
    
    args = parser.parse_args()
    
    # 데이터 수집
    result = collect_historical_data(args.symbol, args.days)
    
    # JSON 파일로 저장
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    # 결과 출력 (Java에서 로그로 확인 가능)
    if result['success']:
        print(f"SUCCESS: {result['symbol']} - {result['count']} candles")
        sys.exit(0)
    else:
        print(f"FAILED: {result['symbol']} - {result['message']}")
        sys.exit(1)


if __name__ == '__main__':
    main()
