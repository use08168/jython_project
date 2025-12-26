<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Page - Spring Boot + JSP Integration</title>
    <style>
        /* 
            ========================================
            간단한 테스트 페이지 스타일
            ========================================
        */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        
        h1 {
            color: #2962ff;
            border-bottom: 3px solid #26a69a;
            padding-bottom: 10px;
        }
        
        h2 {
            color: #26a69a;
        }
        
        p {
            color: #666;
            font-size: 14px;
        }
        
        .info-box {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <!-- 
        ========================================
        Spring Boot + JSP 통합 테스트 페이지
        ========================================
        
        목적:
        - Spring Boot와 JSP 연동 확인
        - JSP EL (Expression Language) 테스트
        - JSP Scriptlet 동작 확인
        
        사용 시나리오:
        - 프로젝트 초기 설정 검증
        - JSP 엔진 정상 작동 확인
        - Controller → View 데이터 전달 테스트
        
        접속 URL:
        - http://localhost:8080/test (예상)
        - Controller에서 매핑 필요
        
        ========================================
    -->
    
    <h1>Spring Boot + JSP Test</h1>
    
    <!-- 
        ========================================
        JSP EL (Expression Language) 테스트
        ========================================
        
        문법: ${변수명}
        
        동작:
        - Controller에서 Model에 추가한 속성 출력
        - 예: model.addAttribute("testMessage", "Hello JSP!")
        
        장점:
        - 간결한 문법
        - null-safe (null이면 빈 문자열)
        - JSTL과 호환
        
        예시 Controller:
        @GetMapping("/test")
        public String testPage(Model model) {
            model.addAttribute("testMessage", "JSP is working!");
            return "test";
        }
    -->
    <h2>${testMessage}</h2>
    
    <!-- 
        ========================================
        JSP Scriptlet 테스트
        ========================================
        
        문법: <%= Java 표현식 %>
        
        동작:
        - Java 코드 직접 실행
        - 현재 시각 출력 (서버 시간)
        
        주의:
        - JSP Scriptlet은 레거시 방식
        - 현대적 JSP에서는 JSTL/EL 권장
        - 간단한 테스트 용도로만 사용
        
        서버 시간:
        - new java.util.Date(): 현재 서버 시각
        - 타임존: JVM 기본 설정 (보통 시스템 타임존)
    -->
    <p>현재 시간: <%= new java.util.Date() %></p>
    
    <div class="info-box">
        <h3>✅ 테스트 항목</h3>
        <ul>
            <li><strong>JSP 엔진:</strong> 정상 작동 (이 페이지가 보이면 OK)</li>
            <li><strong>EL 처리:</strong> ${testMessage} 값이 표시되면 OK</li>
            <li><strong>Scriptlet:</strong> 현재 시간이 표시되면 OK</li>
            <li><strong>한글 인코딩:</strong> 한글이 깨지지 않으면 OK</li>
        </ul>
        
        <h3>📝 설정 확인 사항</h3>
        <ul>
            <li><strong>application.properties:</strong>
                <pre style="background: #f0f0f0; padding: 10px; border-radius: 4px;">
spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp
                </pre>
            </li>
            <li><strong>build.gradle:</strong> Tomcat Embed Jasper 의존성</li>
            <li><strong>디렉토리:</strong> src/main/webapp/WEB-INF/views/</li>
        </ul>
        
        <h3>🔍 트러블슈팅</h3>
        <ul>
            <li><strong>404 Error:</strong> Controller 매핑 확인</li>
            <li><strong>500 Error:</strong> JSP 문법 오류</li>
            <li><strong>빈 화면:</strong> ViewResolver 설정 확인</li>
            <li><strong>한글 깨짐:</strong> UTF-8 인코딩 확인</li>
        </ul>
    </div>
    
    <!-- 
        ========================================
        추가 테스트 예제 (주석 처리)
        ========================================
    -->
    
    <!--
    JSTL 테스트 예시:
    
    <c:if test="${not empty testMessage}">
        <p>메시지가 있습니다: ${testMessage}</p>
    </c:if>
    
    <c:forEach var="i" begin="1" end="5">
        <p>반복 ${i}</p>
    </c:forEach>
    
    <c:choose>
        <c:when test="${testMessage == 'Hello'}">
            <p>인사말입니다</p>
        </c:when>
        <c:otherwise>
            <p>다른 메시지입니다</p>
        </c:otherwise>
    </c:choose>
    -->
    
    <!--
    Controller 예제:
    
    @Controller
    public class TestController {
        
        @GetMapping("/test")
        public String testPage(Model model) {
            model.addAttribute("testMessage", "JSP is working!");
            return "test";  // → /WEB-INF/views/test.jsp
        }
    }
    -->
    
    <!--
    디렉토리 구조:
    
    src/main/
    ├── java/
    │   └── com/weenie_hut_jr/the_salty_spitoon/
    │       └── controller/
    │           └── TestController.java
    └── webapp/
        └── WEB-INF/
            └── views/
                └── test.jsp  ← 이 파일
    -->
</body>
</html>