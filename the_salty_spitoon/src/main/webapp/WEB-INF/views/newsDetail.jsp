<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${news.title} - The Salty Spitoon</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f7fa;
            color: #333;
            line-height: 1.8;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }

        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 0;
            margin-bottom: 30px;
        }

        .back-link {
            display: inline-block;
            color: white;
            text-decoration: none;
            margin-bottom: 15px;
            font-size: 1.1em;
            opacity: 0.9;
            transition: opacity 0.3s;
        }

        .back-link:hover {
            opacity: 1;
        }

        .article {
            background: white;
            border-radius: 10px;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .article-meta {
            display: flex;
            gap: 20px;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
            flex-wrap: wrap;
        }

        .symbol-badge {
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 1em;
        }

        .publisher {
            color: #666;
            font-weight: 500;
        }

        .publish-date {
            color: #999;
            font-size: 0.95em;
        }

        .article-title {
            font-size: 2.2em;
            font-weight: 700;
            line-height: 1.3;
            margin-bottom: 20px;
            color: #222;
        }

        .article-summary {
            font-size: 1.2em;
            color: #666;
            font-style: italic;
            margin-bottom: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            border-radius: 5px;
        }

        .article-content {
            font-size: 1.1em;
            line-height: 1.9;
            color: #444;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .source-link {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
            text-align: center;
        }

        .source-link a {
            display: inline-block;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            transition: background 0.3s;
        }

        .source-link a:hover {
            background: #5568d3;
        }

        @media (max-width: 768px) {
            .container {
                padding: 10px;
            }

            .article {
                padding: 20px;
            }

            .article-title {
                font-size: 1.6em;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <a href="/news" class="back-link">← Back to News</a>
        </div>
    </header>

    <div class="container">
        <article class="article">
            <div class="article-meta">
                <span class="symbol-badge">${news.symbol}</span>
                <span class="publisher">📰 ${news.publisher}</span>
                <span class="publish-date">
                    🕒 ${news.publishedAt.toString().substring(0, 16).replace('T', ' ')}
                </span>
            </div>

            <h1 class="article-title">${news.title}</h1>

            <c:if test="${not empty news.summary}">
                <div class="article-summary">
                    ${news.summary}
                </div>
            </c:if>

            <div class="article-content">
                ${news.fullContent}
            </div>

            <div class="source-link">
                <a href="${news.url}" target="_blank" rel="noopener noreferrer">
                    Read Original Article ↗
                </a>
            </div>
        </article>
    </div>
</body>
</html>