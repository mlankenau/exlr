defmodule ExLR.Parser.StateTest do
  use ExUnit.Case
  alias ExLR.Parser.State
  alias ExLR.Parser.StatePart
  alias ExLR.Parser.Rule

  @rules [
    %Rule{id: 1, dest: :Z, symbols: [:S, :"$"]},
    %Rule{id: 2, dest: :S, symbols: [:a, :B]},
    %Rule{id: 3, dest: :B, symbols: [:c, :B]},
    %Rule{id: 4, dest: :B, symbols: [:d]}
  ]

  test "building" do
    [first | _rem] = @rules
    assert State.build(first, @rules) == %State{
      id: 0,
      parts: [
        %StatePart{rem: [:S, :"$"], rule: %Rule{id: 1, dest: :Z, symbols: [:S, :"$"]}},
        %StatePart{rem: [:a, :B], rule: %Rule{id: 2, dest: :S, symbols: [:a, :B]}}
      ]
    }
  end
end
