<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.sql.DataSource, javax.naming.InitialContext, javax.naming.Context, java.sql.Connection, java.sql.Statement, java.sql.ResultSet, java.sql.SQLException" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%!
    // 테스트에 사용할 테이블 이름 (다른 테이블과 겹치지 않게)
    private static final String TEST_TABLE_NAME = "JSP_TEMP_TEST_TABLE";
%>
<%
    // 변수 초기화
    String action = request.getParameter("action");
    String statusMessage = "";
    String errorMessage = "";
    List<String> selectResults = new ArrayList<>();

    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;

    // 폼이 전송되었을 때만 (action 파라미터가 있을 때만) DB 작업 수행
    if (action != null) {
        try {
            // JNDI를 통해 DB 커넥션 가져오기
            Context initContext = new InitialContext();
            Context envContext  = (Context)initContext.lookup("java:comp/env");
            
            DataSource ds = (DataSource)envContext.lookup("jdbc/myAppDB"); 
            conn = ds.getConnection();
            stmt = conn.createStatement();

            // 요청된 action에 따라 DDL/DML 수행
            switch (action) {
                case "create":
                    // (예외처리) 혹시 테이블이 남아있으면 삭제 후 생성
                    try { stmt.executeUpdate("DROP TABLE " + TEST_TABLE_NAME); } 
                    catch (SQLException ignore) {
                        statusMessage = "테이블 생성 중 오류 발생: " + ignore.getMessage();
                        ignore.printStackTrace();
                    }
                    
                    stmt.executeUpdate("CREATE TABLE " + TEST_TABLE_NAME + " ( " +
                                       "  id INT PRIMARY KEY AUTO_INCREMENT, " +
                                       "  name VARCHAR(100), " +
                                       "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP " +
                                       ")");
                    statusMessage = "'" + TEST_TABLE_NAME + "' 테이블 생성 성공!";
                    break;
                    
                case "insert":
                    int currentCount = 0;
                    try (
                        ResultSet rsCount = stmt.executeQuery("SELECT COUNT(*) FROM " + TEST_TABLE_NAME);
                    ) {
                        if (rsCount.next()) {
                            currentCount = rsCount.getInt(1);
                        }
                    }
                    String name = (currentCount + 1) + "번째 데이터";
                    int count = stmt.executeUpdate(
                        "INSERT INTO " + TEST_TABLE_NAME + " (name) VALUES ('" + name + "')"
                        );
                    
                    statusMessage = (count) + "건의 데이터 INSERT 성공!";
                    break;

                case "select":
                    // SELECT는 여기서 바로 처리
                    rs = stmt.executeQuery("SELECT * FROM " + TEST_TABLE_NAME + " ORDER BY id");
                    while (rs.next()) {
                        String row = String.format("ID: %d, Name: %s, Time: %s", 
                                     rs.getInt("id"), rs.getString("name"), rs.getTimestamp("created_at"));
                        selectResults.add(row);
                    }
                    if (selectResults.isEmpty()) {
                        statusMessage = "테이블에 데이터가 없습니다.";
                    } else {
                        statusMessage = selectResults.size() + "건의 데이터 SELECT 성공!";
                    }
                    break;

                case "delete":
                    int deleteCount = stmt.executeUpdate(
                        "DELETE FROM " + TEST_TABLE_NAME + " ORDER BY id DESC LIMIT 1"
                        );
                    
                    if (deleteCount > 0) {
                        statusMessage = deleteCount + "건의 마지막 데이터 DELETE 성공!";
                    } else {
                        statusMessage = "삭제할 데이터가 없습니다.";
                    }
                    break;

                case "drop":
                    stmt.executeUpdate("DROP TABLE IF EXISTS " + TEST_TABLE_NAME);
                    statusMessage = "'" + TEST_TABLE_NAME + "' 테이블 DROP 성공!";
                    break;
            }

        } catch (Exception e) {
            //  예외 처리
            errorMessage = "작업 실패: " + e.getMessage();
            // e.printStackTrace(); // 콘솔에 상세 로그 출력
        } finally {
            // 자원 반납
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>DB DDL/DML 테스트 페이지</title>
    <style>
        body { font-family: sans-serif; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; border: 1px solid #ccc; padding: 20px; border-radius: 8px; }
        h1 { text-align: center; }
        .btn-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin-bottom: 20px; }
        button { padding: 12px; font-size: 16px; cursor: pointer; border: none; border-radius: 5px; }
        button.create { background-color: #28a745; color: white; }
        button.insert { background-color: #007bff; color: white; }
        button.select { background-color: #17a2b8; color: white; }
        button.delete { background-color: #ffc107; color: black; }
        button.drop { background-color: #dc3545; color: white; }
        #results { margin-top: 20px; padding: 15px; border-radius: 5px; }
        #results.success { background-color: #e6ffed; border: 1px solid #b7ebc0; color: #257938; }
        #results.error { background-color: #fff0f1; border: 1px solid #f5c6cb; color: #721c24; }
        ul { background-color: #f8f9fa; padding: 10px 10px 10px 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>JNDI DB 테스트 (jdbc/myAppDB)</h1>
        <p><b>테스트 테이블명:</b> <%= TEST_TABLE_NAME %></p>
        
        <div class="btn-grid">
            <form action="" method="POST">
                <input type="hidden" name="action" value="create">
                <button type="submit" class="create" style="width:100%;">1. 테이블 생성 (CREATE)</button>
            </form>
            <form action="" method="POST">
                <input type="hidden" name="action" value="insert">
                <button type="submit" class="insert" style="width:100%;">2. 데이터 삽입 (INSERT)</button>
            </form>
            <form action="" method="POST">
                <input type="hidden" name="action" value="select">
                <button type="submit" class="select" style="width:100%;">3. 데이터 조회 (SELECT)</button>
            </form>
            <form action="" method="POST">
                <input type="hidden" name="action" value="delete">
                <button type="submit" class="delete" style="width:100%;">4. 데이터 삭제 (DELETE)</button>
            </form>
            <form action="" method="POST">
                <input type="hidden" name="action" value="drop">
                <button type="submit" class="drop" style="width:100%;">5. 테이블 삭제 (DROP)</button>
            </form>
        </div>

        <% if (!statusMessage.isEmpty() || !errorMessage.isEmpty()) { %>
            <div id="results" class="<%= !errorMessage.isEmpty() ? "error" : "success" %>">
                <% if (!errorMessage.isEmpty()) { %>
                    <h3>실행 실패 😢</h3>
                    <p><%= errorMessage %></p>
                <% } else { %>
                    <h3>실행 성공 ✅</h3>
                    <p><%= statusMessage %></p>
                <% } %>
                
                <%-- SELECT 결과가 있으면 목록으로 표시 --%>
                <% if (!selectResults.isEmpty()) { %>
                    <h4>[조회 결과]</h4>
                    <ul>
                        <% for (String row : selectResults) { %>
                            <li><%= row %></li>
                        <% } %>
                    </ul>
                <% } %>
            </div>
        <% } %>
    </div>
</body>
</html>
