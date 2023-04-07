defmodule ExLR.Parser.StateMachineTest do
  use ExUnit.Case
  alias ExLR.Parser.StateMachine
  alias ExLR.Parser.Rule

  @rules [
    %Rule{dest: :Z, symbols: [:S, :"$"]},
    %Rule{dest: :S, symbols: [:a, :B], accept: true},
    %Rule{dest: :B, symbols: [:c, :B]},
    %Rule{dest: :B, symbols: [:d]}
  ]

  test "build state machine" do
    sm = StateMachine.build(@rules)
    assert %{states: _states} = sm
  end
end
