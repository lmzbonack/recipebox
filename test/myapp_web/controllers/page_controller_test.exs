defmodule MyappWeb.PageControllerTest do
  use MyappWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Home Page"
  end
end
