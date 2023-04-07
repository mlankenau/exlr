defmodule ExLR.ExampleXMLTest do
  use ExUnit.Case
  use ExLR

  terminal :xml_text, stop_chars: [?>, ?<, 32, ?/, ?", ?=]

  lr do
    XmlDoc <- Element

    ContentList <- Content + ContentList        = fn [c, cl] -> [c | cl] end
    ContentList <- Content                      = fn [c] -> [c] end

    Content <- Element
    Content <- :xml_text                        = fn [text] -> text end

    Element <- SelfClosingElement
    Element <- OpenElement + CloseElement       = fn [oe, _ce] -> oe end
    Element <- OpenElement + ContentList + CloseElement       = fn
      [{name, attr}, list, name] -> {name, attr, list}
      [{name, _attr}, _list, _] -> raise "missing closing element for #{name}"
    end

    SelfClosingElement <- "<" + :xml_text  + :ws + Attributes + "/>"  = fn [_, name, _, attr_list, _]  -> {name, attr_list |> Enum.into(%{}), []} end
    SelfClosingElement <- "<" + :xml_text  + "/>"  = fn [_, name, _]  -> {name, %{}} end

    OpenElement <- "<" + :xml_text  + :ws + Attributes + ">"  = fn [_, name, _, attr_list, _]  -> {name, attr_list |> Enum.into(%{})} end
    OpenElement <- "<" + :xml_text + ">"  = fn [_, name, _]  -> {name, %{}} end
    CloseElement <- "</" + :xml_text + ">"  = fn [_, name, _]  -> name end

    Attributes <- Attribute + :ws + Attributes  = fn [a, _, list] -> [a | list] end
    Attributes <- Attribute                     = fn [a] -> [a] end

    Attribute <- :xml_text + "=" + :quoted_text     = fn [name, _, value] -> {name, value} end
  end

  test "self-closing without attributes" do
    assert parse("<myelement/>") == {:ok, {"myelement", %{}}}
  end

  test "parse self-closing" do
    assert parse("<myelement foo=\"bar\"/>") == {:ok, {"myelement", %{"foo" => "bar"}, []}}
  end

  test "parse open and close" do
    assert parse("<myelement foo=\"bar\"></myelement>") == {:ok, {"myelement", %{"foo" => "bar"}}}
  end

  test "parse open and close with text content" do
    assert parse("<myelement foo=\"bar\">bla</myelement>") == {:ok, {"myelement", %{"foo" => "bar"}, ["bla"]}}
  end

  test "encapsulated elements" do
    assert parse("<myelement><foo>bla</foo></myelement>") == {:ok, {"myelement", %{}, [{"foo", %{}, ["bla"]}]}}
  end
end
