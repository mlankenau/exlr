defmodule ExLR.LexerTest do
  use ExUnit.Case
  alias ExLR.Lexer.Lexer


  describe "scan" do
    test "single symbol" do
      lexer =
        Lexer.init()
        |> Lexer.add_terminal("foo")

      assert {:ok, [{"foo", "foo", {0,0}}, {:"$", nil, {0,0}}]} = Lexer.scan("foo", lexer)
    end

    test "multiple symbol" do
      lexer =
        Lexer.init()
        |> Lexer.add_terminal("foo")
        |> Lexer.add_terminal("bar")

      assert {:ok, [{"foo", "foo", {0, 0}}, {"bar", "bar", {0, 3}}, {:"$", nil, {0, 3}}]} = Lexer.scan("foobar", lexer)
    end

    test "multiple symbol with whitespaces" do
      lexer =
        Lexer.init(skip_whitespaces: true)
        |> Lexer.add_terminal("foo")
        |> Lexer.add_terminal("bar")

      assert {:ok, [{"foo", "foo", {0, 0}}, {"bar", "bar", {0, 4}}, {:"$", nil, {0, 4}}]} = Lexer.scan("foo bar", lexer)
    end

    test "more realistic example" do
      lexer =
        Lexer.init(skip_whitespaces: true)
        |> Lexer.add_terminal(:integer)
        |> Lexer.add_terminal("a")
        |> Lexer.add_terminal("=")

      assert {:ok, [{"a", "a", {0, 0}}, {"=", "=", {0, 2}}, {:integer, 123, {0, 4}}, {:"$", nil, {0, 4}}]} = Lexer.scan("a = 123", lexer)
    end
  end

  describe "error handling" do
    test "single symbol" do
      lexer =
        Lexer.init()
        |> Lexer.add_terminal("foo")

      assert {:error, :unknown_symbol, {0, 0}} = Lexer.scan("fou", lexer)
    end

    test "single symbol, not at pos 0" do
      lexer =
        Lexer.init(skip_whitespaces: true)
        |> Lexer.add_terminal("foo")

      assert {:error, :unknown_symbol, {0, 2}} = Lexer.scan("  fou", lexer)
    end

    test "show correct position of unknown symbol" do
      lexer =
        Lexer.init(skip_whitespaces: true)
        |> Lexer.add_terminal("foo")

      assert {:error, :unknown_symbol, {0, 3}} = Lexer.scan("foo = ", lexer)
    end
  end


  describe "special cases" do
    test "quoted text" do
      lexer =
        Lexer.init(skip_whitespaces: true)
        |> Lexer.add_terminal(:quoted_text)
      Lexer.scan("  \"a\" ", lexer)
    end
  end
end
