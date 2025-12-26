"""
========================================
실제 뉴스 데이터 인코딩 테스트
========================================
"""

import json
import gzip
import base64
from pathlib import Path
from datetime import datetime
import pytz

kst = pytz.timezone('Asia/Seoul')

# ========================================
# 절대 경로 설정
# ========================================

# 이 스크립트의 위치 기준
SCRIPT_DIR = Path(__file__).parent.absolute()

INPUT_FILE = SCRIPT_DIR / 'output' / 'news_details.json'
OUTPUT_FILE = SCRIPT_DIR / 'output' / 'test_news.json'
TEST_COUNT = 10


def load_news_details():
    """news_details.json 로드"""
    try:
        print(f"\n📂 파일 경로 확인:")
        print(f"   스크립트 위치: {SCRIPT_DIR}")
        print(f"   입력 파일: {INPUT_FILE}")
        print(f"   파일 존재 여부: {INPUT_FILE.exists()}")
        
        if not INPUT_FILE.exists():
            print(f"\n❌ 파일이 존재하지 않습니다!")
            print(f"   찾는 위치: {INPUT_FILE}")
            print(f"\n확인 사항:")
            print(f"   1. python/output/news_details.json 파일이 있나요?")
            print(f"   2. news_detail_crawler.py를 실행했나요?")
            raise FileNotFoundError(f"파일을 찾을 수 없습니다: {INPUT_FILE}")
        
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        news_list = data.get('data', [])
        print(f"\n✅ 파일 로드 성공")
        print(f"   총 뉴스: {len(news_list)}개")
        
        return news_list
        
    except Exception as e:
        print(f"❌ 파일 로드 실패: {e}")
        raise


def encode_news_data(news_item):
    """
    뉴스 데이터 인코딩 (gzip + URL-safe Base64)
    """
    data_to_encode = {
        'url': news_item.get('url', ''),
        'summary': news_item.get('summary', ''),
        'publisher': news_item.get('publisher', ''),
        'full_content': news_item.get('full_content', '')
    }
    
    json_str = json.dumps(data_to_encode, ensure_ascii=False)
    compressed = gzip.compress(json_str.encode('utf-8'))
    encoded = base64.urlsafe_b64encode(compressed).decode('utf-8').rstrip('=')
    
    return encoded, data_to_encode


def create_test_data(news_list, count=10):
    """테스트용 데이터 생성"""
    print(f"\n🔧 상위 {count}개 뉴스 인코딩 시작...")
    print("="*80)
    
    test_data = []
    
    for idx, news in enumerate(news_list[:count]):
        title = news.get('title', 'No Title')
        print(f"\n📰 [{idx+1}/{count}] {title[:60]}...")
        
        encoded_data, original_data = encode_news_data(news)
        
        original_json = json.dumps(original_data, ensure_ascii=False)
        original_length = len(original_json)
        encoded_length = len(encoded_data)
        compression_ratio = (encoded_length / original_length) * 100
        
        print(f"   원본: {original_length:,} chars")
        print(f"   압축: {encoded_length:,} chars")
        print(f"   압축률: {compression_ratio:.1f}%")
        
        test_item = {
            'symbol': news.get('symbol', 'UNKNOWN'),
            'title': title,
            'published_at': news.get('published_at', ''),
            'thumbnail_url': news.get('thumbnail_url', ''),
            'crawled_at': news.get('crawled_at', ''),
            'original_data': original_data,
            'encoded_data': encoded_data,
            'original_length': original_length,
            'encoded_length': encoded_length,
            'compression_ratio': round(compression_ratio, 1)
        }
        
        test_data.append(test_item)
    
    print("\n" + "="*80)
    print(f"✅ {len(test_data)}개 뉴스 인코딩 완료")
    
    return test_data


def save_test_data(test_data, output_file):
    """테스트 데이터를 JSON 파일로 저장"""
    try:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        output = {
            'timestamp': datetime.now(kst).strftime('%Y-%m-%d %H:%M:%S'),
            'total_news': len(test_data),
            'description': 'Python-Java 인코딩 연동 테스트용 데이터',
            'encoding_method': 'gzip + URL-safe Base64',
            'data': test_data
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 테스트 데이터 저장 완료")
        print(f"   파일: {output_file}")
        print(f"   크기: {output_file.stat().st_size:,} bytes")
        
    except Exception as e:
        print(f"❌ 저장 실패: {e}")
        raise


def print_summary(test_data):
    """통계 요약 출력"""
    print("\n" + "="*80)
    print("📊 인코딩 통계")
    print("="*80)
    
    total_original = sum(item['original_length'] for item in test_data)
    total_encoded = sum(item['encoded_length'] for item in test_data)
    avg_compression = sum(item['compression_ratio'] for item in test_data) / len(test_data)
    
    print(f"총 뉴스: {len(test_data)}개")
    print(f"원본 총 길이: {total_original:,} chars")
    print(f"압축 총 길이: {total_encoded:,} chars")
    print(f"평균 압축률: {avg_compression:.1f}%")
    print(f"절약된 용량: {total_original - total_encoded:,} chars")
    print()
    
    print("압축률 분포:")
    for item in test_data:
        symbol = item['symbol']
        ratio = item['compression_ratio']
        bar_length = int(ratio / 2)
        bar = '█' * bar_length
        print(f"  {symbol:6} {ratio:5.1f}% {bar}")
    
    print("="*80)


def main():
    """메인 함수"""
    print("="*80)
    print("🧪 실제 뉴스 데이터 인코딩 테스트")
    print("="*80)
    print(f"입력: {INPUT_FILE}")
    print(f"출력: {OUTPUT_FILE}")
    print(f"개수: {TEST_COUNT}개")
    print("="*80)
    
    try:
        # 1. 뉴스 데이터 로드
        news_list = load_news_details()
        
        # 2. 테스트 데이터 생성
        test_data = create_test_data(news_list, count=TEST_COUNT)
        
        # 3. 저장
        save_test_data(test_data, OUTPUT_FILE)
        
        # 4. 통계 출력
        print_summary(test_data)
        
        print("\n✅ 테스트 데이터 생성 완료!")
        print(f"\nJava 테스트 실행:")
        print(f"  1. IntelliJ에서 EncodingTest.java 열기")
        print(f"  2. testRealNewsData() 메서드 실행")
        print("="*80)
        
    except Exception as e:
        print(f"\n❌ 에러 발생: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()