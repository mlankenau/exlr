defmodule ExLR.Parser.State do
  import ExLR.Lexer.Symbol
  alias ExLR.Parser.StatePart
  alias ExLR.Parser.Rule

  defstruct id: 0,
            parts: [],
            rules: %{},
            goto: %{}

  def build(%Rule{} = rule, rules) do
    parts =
      [StatePart.build_initial(rule)]
      |> _fill_sub_parts(rules)

    %__MODULE__{parts: parts}
  end
  def build(%__MODULE__{parts: parts} = state, rules) do
    parts =
      parts
      |> _fill_sub_parts(rules)

    %__MODULE__{state | parts: parts}
  end

  def add_reduce(%__MODULE__{parts: parts} = state, rules) do
    reduces =
      parts
      |> Enum.filter(fn part -> is_nil(StatePart.next_symbol(part)) end)
      |> Enum.reduce(%{}, fn %StatePart{rule: %{id: rule_id, dest: dest}}, acc ->
        Rule.follow(dest, rules)
        |> Enum.reduce(acc, fn s, acc ->
          Map.put(acc, s, {:reduce, rule_id})
        end)
      end)
    %__MODULE__{
      state |
      rules: Map.merge(state.rules, reduces)
    }
  end

  def _fill_sub_parts(parts, rules) do
    follow_up_non_terminals =
      parts
      |> Enum.map(&StatePart.next_symbol/1)
      |> Enum.filter(& not is_terminal(&1))

    new_parts =
      rules
      |> Enum.filter(fn %Rule{dest: dest} -> dest in follow_up_non_terminals end)
      |> Enum.map(&StatePart.build_initial/1)

    (new_parts -- parts)
    |> case do
      [] -> parts
      list -> _fill_sub_parts(parts ++ list, rules)
    end
    |> Enum.sort()
  end

  def find_transitions(%__MODULE__{parts: parts}, rules) do
    parts
    |> Enum.map(&StatePart.next_symbol/1)
    |> Enum.filter(& &1)
    |> Enum.map(fn symbol ->
      new_part_list =
        parts
        |> Enum.filter(fn p -> StatePart.next_symbol(p) == symbol end)
        |> Enum.map(fn p ->
          StatePart.slide_one_symbol(p)
        end)

      new_state =
        %__MODULE__{parts: new_part_list}
        |> build(rules)

      {symbol, new_state}
    end)
  end

  def print(%__MODULE__{id: id, parts: parts, rules: rules}) do
    IO.puts "State #{id}"
    Enum.map(parts, fn part ->
      IO.puts "  " <> StatePart.to_string(part)
    end)
    IO.puts ""
    Enum.map(rules, fn {k, v} ->
      IO.puts "  #{k} => #{inspect v}"
    end)
    IO.puts ""
  end

  def to_dot(%__MODULE__{id: id, parts: parts, rules: _rules}) do
    parts =
      Enum.map(parts, fn part ->
        StatePart.to_string(part)
      end)
      |> Enum.join("\\n")

    """
      state#{id} [
          label = "(#{id})\\n#{parts}";
      ];
    """
  end
  def to_dot_transitions(%__MODULE__{id: id, parts: _parts, rules: rules, goto: goto}) do
    (Enum.map(goto, fn
      {k, v} -> "state#{id} -> state#{v} [label=\"#{k}\"]"
    end) ++
    Enum.map(rules, fn
      {k, {:shift, v}} -> "state#{id} -> state#{v} [label=\"#{k}\"]"
      {_k, {:reduce, _v}} -> ""
      {_k, _accept} -> ""
    end))
    |> Enum.join("\n")
  end
end
