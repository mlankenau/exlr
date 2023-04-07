defmodule ExLR.Parser.RuleTest do
  use ExUnit.Case
  alias ExLR.Parser.Rule

  @rules [
    %Rule{id: 1, dest: :A, symbols: [:C, :B]},
    %Rule{id: 2, dest: :B, symbols: [:plus, :C, :B]},
    %Rule{id: 3, dest: :C, symbols: [:E, :D]},
    %Rule{id: 4, dest: :D, symbols: [:mul, :E, :D]},
    %Rule{id: 5, dest: :E, symbols: [:bo, :A, :bc]},
    %Rule{id: 6, dest: :E, symbols: [:i]}
  ]

  test "first" do
    assert Rule.first(:A, @rules) == [:bo, :i]
    assert Rule.first(:B, @rules) == [:plus]
    assert Rule.first(:C, @rules) == [:bo, :i]
    assert Rule.first(:D, @rules) == [:mul]
    assert Rule.first(:E, @rules) == [:bo, :i]
  end

  test "follow" do
    assert Rule.follow(:A, @rules) == [:bc]
    assert Rule.follow(:B, @rules) == [:bc]
    assert Rule.follow(:C, @rules) == [:plus]
    assert Rule.follow(:D, @rules) == [:plus]
    assert Rule.follow(:E, @rules) == [:mul]
  end
end
