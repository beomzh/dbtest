<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.sql.DataSource, javax.naming.InitialContext, javax.naming.Context, java.sql.Connection, java.sql.ResultSet, java.sql.Statement" %>
<!DOCTYPE html>
<html>
<head>
    <title>DB Failover 테스트 (Gradle/Kotlin)</title>
</head>
<body>
    <h1>DB 연결 테스트 (Active-Standby)</h1>
    <%
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        String serverHostname = "N/A";
        String schemaName = "N/A"; 
        String errorMessage = "";

        try {
            Context initContext = new InitialContext();
            Context envContext  = (Context)initContext.lookup("java:comp/env");
            DataSource ds = (DataSource)envContext.lookup("jdbc/myAppDB"); 
            conn = ds.getConnection();

            // @@hostname: 현재 연결된 MariaDB 서버의 호스트명을 반환
            // DATABASE(): 현재 연결된 스키마(DB)명을 반환
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT @@hostname AS 'ServerName', DATABASE() AS 'SchemaName'"); 

            if (rs.next()) {
                serverHostname = rs.getString("ServerName");
                schemaName = rs.getString("SchemaName"); 
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
            e.printStackTrace(response.getWriter());
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (stmt != null) try { stmt.close(); } catch (Exception e) {}
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    %>

    <% if (errorMessage.isEmpty()) { %>
        <h2>연결 성공! ✅</h2>
        <p><strong>현재 연결된 DB 서버:</strong> <b style="color: blue; font-size: 1.2em;"><%= serverHostname %></b></p>
        <p><strong>현재 연결된 스키마:</strong> <b style="color: green; font-size: 1.2em;"><%= schemaName %></b></p>
        
        <p>
            <b>테스트 방법:</b><br>
            1. 현재 연결된 DB 서버(<b><%= serverHostname %></b>)의 MariaDB 서비스를 중지시킵니다.<br>
            2. 잠시 후 (약 30초 이내) 이 페이지를 새로고침합니다.<br>
            3. '현재 연결된 DB 서버'가 다른 Standby 서버의 호스트 이름으로 변경되는지 확인합니다.
        </p>
    <% } else { %>
        <h2>연결 실패 😢</h2>
        <p style="color: red;"><strong>에러 메시지:</strong> <%= errorMessage %></p>
    <% } %>

</body>
</html>
