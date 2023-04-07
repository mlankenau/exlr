defmodule ExLR.DSLTest do
  use ExUnit.Case
  use ExLR

  lr skip_whitespaces: true do
    S <- S + "+" + :integer = fn ([a, _, b]) -> a + b end
    S <- :integer           = fn ([a]) -> a end
  end

  test "parse by symbols" do
    assert parse([{:integer, 3, {0, 0}}, {"+", nil, {0, 0}}, {:integer, 4, {0, 0}}, {:"$", nil, {0, 0}}]) ==
      {:ok, 7}
  end

  test "parse by string" do
    assert parse("3+4") ==
      {:ok, 7}
  end

  test "parse by string more complex" do
    assert parse("3+4 + 7") ==
      {:ok, 14}
  end

  test "_parse_symbols" do
    res = ExLR._parse_symbols({:+, [line: 10],
          [
            {:+, [line: 10], [{:__aliases__, [line: 10], [:P]}, "*"]},
            {:__aliases__, [line: 10], [:N]}
          ]})

    assert res |> List.flatten == [:N, "*", :P]
  end
end
