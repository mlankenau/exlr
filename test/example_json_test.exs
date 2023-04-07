defmodule ExLR.ExampleJsonTest do
  use ExUnit.Case
  use ExLR

  lr skip_whitespaces: true do
    Element <- Map
    Element <- List
    Element <- :quoted_text
    Element <- :integer
    Element <- Boolean

    Boolean <- "true"                            = fn _ -> true end
    Boolean <- "false"                           = fn _ -> false end

    List <- "[" + ListElements + "]"             = fn [_, elements, _] -> elements end
    ListElements <- Element                      = fn [e] -> [e] end
    ListElements <- Element + "," + ListElements = fn [e, _, list] -> [e | list] end
    List <- List + "," + Element

    Map <- "{" + AttrList + "}"                  = fn [_, list, _] -> list |> Enum.into(%{}) end
    AttrList <- Attr                             = & &1
    AttrList <- Attr + "," + AttrList            = fn [a, _, l] -> [a | l] end
    Attr <- :quoted_text  + ":" + Element        = fn [n, _, qt] -> {n, qt} end
  end

  test "parse a obect" do
    assert parse("{ \"a\": \"foo\", \"b\": 123 }") == {:ok, %{"a" => "foo", "b" => 123}}
  end

  test "parse a List" do
    assert parse("[1, 2, 3]") == {:ok, [1, 2, 3]}
  end

  test "parse a Boolean" do
    assert parse("true") == {:ok, true}
  end
end
