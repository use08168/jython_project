package com.weenie_hut_jr.the_salty_spitoon;

import org.junit.jupiter.api.Test;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ========================================
 * 인코딩/디코딩 테스트
 * ========================================
 */
public class EncodingTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 테스트 데이터 생성
     */
    private Map<String, String> createTestData() {
        Map<String, String> data = new HashMap<>();
        data.put("url",
                "https://finance.yahoo.com/news/google-started-the-year-behind-in-the-ai-race-it-ended-2025-on-top-150352574.html");
        data.put("summary", "Google's AI bounced back in a big way in 2025.");
        data.put("publisher", "Yahoo Finance");
        data.put("full_content",
                "Google (GOOG, GOOGL) entered 2025 in a difficult position. " +
                        "While its stock price rose 36% in 2024, the company was still largely perceived " +
                        "by Wall Street as playing second (or third) fiddle to OpenAI (OPAI.PVT) in the AI race.\n\n" +

                        "Fast-forward to today, and Google is stealing the show, while OpenAI CEO Sam Altman " +
                        "has declared a \"code red\" emergency as the company works to match Google's latest " +
                        "Gemini 3 AI models. It's an interesting twist, given that Google declared its own " +
                        "code red after ChatGPT hit the market in 2022.\n\n" +

                        "Google is also catching up to OpenAI in the key monthly active user (MAU) metric.\n\n" +

                        "Then there are Google chip wins. In October, Claude developer Anthropic (ANTH.PVT) " +
                        "announced it was expanding its plan to use Google's AI chips, including using up to " +
                        "1 million processors, to power its AI software.\n\n" +

                        "Google is also in talks to provide its chips to Facebook and Instagram parent company " +
                        "Meta (META) to run its AI products, according to The Information.\n\n" +

                        "It all added up to a strong 2025 for the search giant, setting it up for continued " +
                        "success in the year ahead.\n\n" +

                        "\"Google will be the best performing Mag 7 stock in CY26,\" Deepwater Asset Management " +
                        "managing partner Gene Munster wrote in a Dec. 11 investor note.\n\n" +

                        "\"Google is in the strongest position when it comes to a fully integrated AI stack,\" " +
                        "he wrote. \"Gemini is a leading model, its user base is expanding faster than OpenAI's, " +
                        "Search is integrating AI effectively with ads reportedly on the way, and [Google Cloud " +
                        "Platform] continues to hold its ground in the infrastructure buildout cycle.\"\n\n" +

                        "Google counts its AI revenue as part of its Google Cloud Platform (GCP) business. " +
                        "According to the company, that has given GCP a significant boost. In Q3, Google said " +
                        "its GCP revenue grew 34% year over year to $15.1 billion. It rose 32% in the prior quarter.\n\n"
                        +

                        "The number of new customers to the GCP jumped 34%.\n\n" +

                        "\"Our complete enterprise AI product portfolio is accelerating growth in revenue, " +
                        "operating margins, and backlog,\" CEO Sundar Pichai said during the company's latest " +
                        "earnings call.\n\n" +

                        "According to Pichai, Google signed more deals worth more than $1 billion in its third " +
                        "quarter than it did in the previous two years combined. More than 70% of the company's " +
                        "existing cloud customers are using its AI services, he added.\n\n" +

                        "The company has also more deeply intertwined its AI capabilities with Google Search, " +
                        "launching its ChatGPT-like AI Mode for all US users in May at the Google I/O conference " +
                        "and dropping ads into AI Overviews in search.");

        return data;
    }

    /**
     * ========================================
     * Test 1: URL-safe Base64 + gzip
     * ========================================
     */

    @Test
    public void testGzipEncoding() throws Exception {
        System.out.println("=" + "=".repeat(79));
        System.out.println("🧪 Test 1: URL-safe Base64 + gzip");
        System.out.println("=" + "=".repeat(79));

        Map<String, String> testData = createTestData();

        // 1. 인코딩
        String encoded = encodeGzip(testData);
        System.out.println("\n✅ 인코딩 성공");
        System.out.println("원본 JSON 길이: " + objectMapper.writeValueAsString(testData).length() + " chars");
        System.out.println("인코딩 길이: " + encoded.length() + " chars");
        System.out.println("압축률: " + String.format("%.1f%%",
                (double) encoded.length() / objectMapper.writeValueAsString(testData).length() * 100));
        System.out.println("\n샘플 (처음 100자):");
        System.out.println(encoded.substring(0, Math.min(100, encoded.length())) + "...");

        // 2. 디코딩
        Map<String, String> decoded = decodeGzip(encoded);
        System.out.println("\n✅ 디코딩 성공");

        // 3. 검증
        boolean isValid = validateData(testData, decoded);
        System.out.println("\n🔍 정보 손실 검증:");
        System.out.println("전체 일치: " + (isValid ? "✅ 일치" : "❌ 불일치"));

        // JUnit Assertion
        assertTrue(isValid, "디코딩된 데이터가 원본과 일치해야 합니다");

        // 4. 필드별 검증
        System.out.println("\n필드별 검증:");
        for (String key : testData.keySet()) {
            String original = testData.get(key);
            String decodedValue = decoded.get(key);

            boolean match = original.equals(decodedValue);
            System.out.println(String.format("  %s %-15s: %s (%d chars)",
                    match ? "✅" : "❌",
                    key,
                    match ? "일치" : "불일치",
                    original.length()));

            // JUnit Assertion
            assertEquals(original, decodedValue, key + " 필드가 일치해야 합니다");
        }

        System.out.println("\n" + "=" + "=".repeat(79));
    }

    /**
     * gzip 인코딩
     */
    private String encodeGzip(Map<String, String> data) throws Exception {
        // 1. Map → JSON 문자열
        String jsonStr = objectMapper.writeValueAsString(data);

        // 2. gzip 압축
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
        try (GZIPOutputStream gzipStream = new GZIPOutputStream(byteStream)) {
            gzipStream.write(jsonStr.getBytes(StandardCharsets.UTF_8));
        }
        byte[] compressed = byteStream.toByteArray();

        // 3. URL-safe Base64 인코딩
        return Base64.getUrlEncoder().withoutPadding().encodeToString(compressed);
    }

    /**
     * gzip 디코딩
     */
    @SuppressWarnings("unchecked")
    private Map<String, String> decodeGzip(String encoded) throws Exception {
        // 1. URL-safe Base64 디코딩
        byte[] compressed = Base64.getUrlDecoder().decode(encoded);

        // 2. gzip 압축 해제
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
        try (GZIPInputStream gzipStream = new GZIPInputStream(new ByteArrayInputStream(compressed))) {
            byte[] buffer = new byte[1024];
            int len;
            while ((len = gzipStream.read(buffer)) > 0) {
                byteStream.write(buffer, 0, len);
            }
        }
        String jsonStr = byteStream.toString(StandardCharsets.UTF_8);

        // 3. JSON 문자열 → Map
        return objectMapper.readValue(jsonStr, Map.class);
    }

    /**
     * 데이터 검증
     */
    private boolean validateData(Map<String, String> original, Map<String, String> decoded) {
        if (original.size() != decoded.size()) {
            return false;
        }

        for (String key : original.keySet()) {
            if (!decoded.containsKey(key)) {
                return false;
            }
            if (!original.get(key).equals(decoded.get(key))) {
                return false;
            }
        }

        return true;
    }

    /**
     * ========================================
     * Test 2: Python-Java 연동 테스트
     * ========================================
     */

    @Test
    public void testPythonJavaInterop() throws Exception {
        System.out.println("=" + "=".repeat(79));
        System.out.println("🔗 Test 2: Python-Java 연동 테스트");
        System.out.println("=" + "=".repeat(79));

        // Python에서 인코딩한 샘플 (위에서 복사한 문자열 붙여넣기)
        String pythonEncoded = "여기에_Python에서_복사한_문자열_붙여넣기";

        if (pythonEncoded.equals("여기에_Python에서_복사한_문자열_붙여넣기")) {
            System.out.println("\n⚠️  Python 샘플 데이터를 붙여넣어주세요!");
            System.out.println("Python 노트북에서 인코딩 결과를 복사해서 위의 pythonEncoded 변수에 붙여넣으세요.");
            return;
        }

        System.out.println("\n📥 Python에서 인코딩한 데이터 수신");
        System.out.println("길이: " + pythonEncoded.length() + " chars");

        // Java에서 디코딩
        Map<String, String> decoded = decodeGzip(pythonEncoded);

        System.out.println("\n✅ Java에서 디코딩 성공!");
        System.out.println("\n필드 확인:");

        for (String key : decoded.keySet()) {
            String value = decoded.get(key);
            System.out.println(String.format("  ✅ %-15s: %d chars", key, value.length()));
        }

        // 검증
        assertNotNull(decoded.get("url"), "url 필드가 존재해야 합니다");
        assertNotNull(decoded.get("summary"), "summary 필드가 존재해야 합니다");
        assertNotNull(decoded.get("publisher"), "publisher 필드가 존재해야 합니다");
        assertNotNull(decoded.get("full_content"), "full_content 필드가 존재해야 합니다");

        System.out.println("\n✅ Python-Java 연동 성공!");
        System.out.println("=" + "=".repeat(79));
    }

    /**
     * ========================================
     * Test 3: 실제 뉴스 데이터 검증
     * ========================================
     */

    @Test
    public void testRealNewsData() throws Exception {
        System.out.println("=" + "=".repeat(79));
        System.out.println("🧪 Test 3: 실제 뉴스 데이터 검증");
        System.out.println("=" + "=".repeat(79));

        // 1. test_news.json 파일 읽기
        String testDataPath = "python/output/test_news.json";
        File testFile = new File(testDataPath);

        if (!testFile.exists()) {
            System.out.println("\n❌ 테스트 파일이 없습니다!");
            System.out.println("먼저 Python 스크립트를 실행하세요:");
            System.out.println("  python python/test_encoding.py");
            fail("test_news.json 파일이 존재하지 않습니다");
            return;
        }

        System.out.println("\n📂 테스트 파일 로드: " + testDataPath);

        // 2. JSON 파싱
        ObjectMapper mapper = new ObjectMapper();
        JsonNode rootNode = mapper.readTree(testFile);

        String timestamp = rootNode.get("timestamp").asText();
        int totalNews = rootNode.get("total_news").asInt();
        JsonNode dataArray = rootNode.get("data");

        System.out.println("   생성 시간: " + timestamp);
        System.out.println("   총 뉴스: " + totalNews + "개");
        System.out.println();

        // 3. 각 뉴스 검증
        int successCount = 0;
        int failCount = 0;
        int totalOriginalLength = 0;
        int totalEncodedLength = 0;

        for (int i = 0; i < dataArray.size(); i++) {
            JsonNode newsNode = dataArray.get(i);

            String symbol = newsNode.get("symbol").asText();
            String title = newsNode.get("title").asText();
            String encodedData = newsNode.get("encoded_data").asText();
            JsonNode originalData = newsNode.get("original_data");

            int originalLength = newsNode.get("original_length").asInt();
            int encodedLength = newsNode.get("encoded_length").asInt();
            double compressionRatio = newsNode.get("compression_ratio").asDouble();

            totalOriginalLength += originalLength;
            totalEncodedLength += encodedLength;

            System.out.println(String.format("📰 [%d/%d] %s - %s",
                    i + 1, totalNews, symbol, title.substring(0, Math.min(50, title.length())) + "..."));
            System.out.println(String.format("   원본: %,d chars | 압축: %,d chars | 압축률: %.1f%%",
                    originalLength, encodedLength, compressionRatio));

            try {
                // 디코딩
                Map<String, String> decoded = decodeGzip(encodedData);
                System.out.println("   ✅ 디코딩 성공");

                // 필드별 검증
                boolean allMatch = true;
                String[] fields = { "url", "summary", "publisher", "full_content" };

                for (String field : fields) {
                    String original = originalData.get(field).asText();
                    String decodedValue = decoded.get(field);

                    if (decodedValue == null) {
                        System.out.println("      ❌ " + field + ": 누락됨");
                        allMatch = false;
                    } else if (!original.equals(decodedValue)) {
                        System.out.println(String.format("      ❌ %s: 불일치 (원본: %d, 디코딩: %d)",
                                field, original.length(), decodedValue.length()));
                        allMatch = false;
                    } else {
                        System.out.println(String.format("      ✅ %-15s: 일치 (%,d chars)",
                                field, original.length()));
                    }
                }

                if (allMatch) {
                    successCount++;
                } else {
                    failCount++;
                }

            } catch (Exception e) {
                System.out.println("   ❌ 디코딩 실패: " + e.getMessage());
                failCount++;
            }

            System.out.println();
        }

        // 4. 최종 결과
        System.out.println("=" + "=".repeat(79));
        System.out.println("📊 최종 결과");
        System.out.println("=" + "=".repeat(79));
        System.out.println(String.format("✅ 성공: %d/%d", successCount, totalNews));
        System.out.println(String.format("❌ 실패: %d/%d", failCount, totalNews));
        System.out.println(String.format("📈 평균 압축률: %.1f%%",
                (double) totalEncodedLength / totalOriginalLength * 100));
        System.out.println(String.format("💾 절약 용량: %,d chars",
                totalOriginalLength - totalEncodedLength));

        if (failCount == 0) {
            System.out.println("✅ 정보 손실: 없음");
        } else {
            System.out.println("⚠️  정보 손실 발견!");
        }

        System.out.println("=" + "=".repeat(79));

        // JUnit Assertion
        assertEquals(0, failCount, "모든 뉴스가 정상적으로 디코딩되어야 합니다");
    }
}