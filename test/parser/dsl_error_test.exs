defmodule ExLR.DSLErrorTest do
  use ExUnit.Case
  require ExLR
  import ExLR

  lr skip_whitespaces: true do
    L <- A = & &1
    L <- A + "," + L = fn [a, _, l] -> [a | l] end
    A <- :text + "=" + :quoted_text = fn [n, _, qt] -> {n, qt} end
  end

  test "eror in input" do
    assert parse("a = foo") ==
      {:error, :unexpected, {:text, "foo", {0, 4}}}
  end
end
