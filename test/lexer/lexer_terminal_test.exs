defmodule ExLR.LexerTerminalTest do
  use ExUnit.Case
  import ExLR.Lexer.Terminal

  describe "generate" do
    test "generate string" do
      t = generate("abc")

      # test initial scan
      assert :no_match = t.scan.(?x, nil)
      assert {:match, "bc"} = t.scan.(?a, nil)

      # test follow-up
      assert :no_match = t.scan.(?y, "bc")
      assert {:match, "c"} = t.scan.(?b, "bc")
    end

    test "generate integer" do
      t = generate(:integer)

      # test initial scan
      assert :no_match = t.scan.(?x, nil)
      assert {:match, :inside_integer} = t.scan.(?0, nil)
      assert {:match, :inside_integer} = t.scan.(?9, nil)

      # test follow-up
      assert :no_match_completed = t.scan.(?y, :inside_integer)
      assert {:match, :inside_integer} = t.scan.(?3, :inside_integer)
    end

    test "quoted text" do
      t = generate(:quoted_text)

      # test initial scan
      assert :no_match = t.scan.(?a, nil)
      assert {:match, :true} = t.scan.(?", nil)

      # test follow-up
      assert {:match, true} = t.scan.(?y, :true)
      assert {:match, false} = t.scan.(?", :true)
      assert :no_match_completed = t.scan.(?3, :false)
    end
  end
end









































