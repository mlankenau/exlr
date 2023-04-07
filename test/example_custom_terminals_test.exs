defmodule ExLR.ExampleCustomTerminalsTest do
  use ExUnit.Case
  use ExLR

  terminal :zip_code, chars: ?0..?9, min: 4, max: 5

  lr skip_whitespaces: true do
    Address <- Zip + City = fn [zip, city] -> %{zip: zip, city: city} end
    Zip <- :zip_code
    City <- :text
  end

  test "success" do
    assert parse("81234 Munich") == {:ok, %{city: "Munich", zip: "81234"}}
    assert parse("8123 Munich") == {:ok, %{city: "Munich", zip: "8123"}}
  end

  test "failure" do
    assert parse("812345 Munich") == {:error, :unexpected, {:text, "812345", {0, 0}}}
    assert parse("812 Munich") == {:error, :unexpected, {:text, "812", {0, 0}}}
  end
end
