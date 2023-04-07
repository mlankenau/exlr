defmodule ExLR.Parser.Rule do
  import ExLR.Lexer.Symbol
  defstruct id: 0,
            dest: nil,
            symbols: [],
            accept: false,
            reduce: nil

  def first(sym, rules) do
    _first(sym, rules, [])
  end

  def follow(sym, rules) do
    _follow(sym, rules, [])
  end

  def all_symbols(rules) do
    rules
    |> Enum.reduce([], fn rule, acc ->
      rule.symbols
      |> Enum.reduce(acc, fn symbol, acc ->
        [symbol | acc]
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def all_terminals(rules) do
    all_symbols(rules)
    |> Enum.filter(&is_terminal/1)
    |> Enum.sort_by(fn
      :"$" -> "_"
      x -> x
    end)
  end

  def all_non_terminals(rules) do
    all_symbols(rules)
    |> Enum.filter(& !is_terminal(&1))
  end
  ######################

  def _first(sym, rules, list) do
    rules
    |> Enum.filter(fn %{id: id} -> id not in list end)
    |> Enum.map(&_first_in_rule(sym, &1, rules, list))
    |> Enum.filter(& &1)
    |> List.flatten()
  end

  def _first_in_rule(sym, %__MODULE__{id: id, dest: sym, symbols: [first | _]}, rules, list) do
    if is_terminal(first) do
      first
    else
      _first(first, rules, [id | list])
    end
  end

  def _first_in_rule(_, _, _, _a), do: nil

  def _follow(sym, rules, list) do
    rules
    |> Enum.filter(fn %{id: id} -> id not in list end)
    |> Enum.map(&_follow_in_rule(sym, &1, &1.symbols, rules, list))
    |> Enum.filter(& &1)
    |> List.flatten()
    |> Enum.uniq()
  end

  def _follow_in_rule(sym, _rule, [sym, next | _rem], rules, _list) do
    if is_terminal(next) do
      next
    else
      first(next, rules)
    end
  end

  def _follow_in_rule(sym, rule, [sym], rules, list) do
    _follow(rule.dest, rules, [rule.id | list])
  end

  def _follow_in_rule(sym, rule, [_ | rem], rules, list) do
    _follow_in_rule(sym, rule, rem, rules, list)
  end

  def _follow_in_rule(_sym, _rule, _, _rules, _list), do: nil



end
