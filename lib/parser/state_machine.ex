defmodule ExLR.Parser.StateMachine do
  alias ExLR.Parser.Rule
  alias ExLR.Parser.State
  alias ExLR.Parser.StatePart
  import ExLR.Lexer.Symbol

  defstruct rules: [], states: %{}, final_state: nil

  def build(rules) do
    rules = _ensure_root(rules)

    # add index to rules
    [first_rule| _] = rules =
      rules
      |> Enum.with_index()
      |> Enum.map(fn {r, i} -> %Rule{r | id: i} end)

    root_state = State.build(first_rule, rules)
    %__MODULE__{states: %{root_state.id => root_state}, rules: rules}
    |> _add_transitions()
    |> _add_reduce()
    |> _put_final_state()
  end

  def _ensure_root([%{dest: :Z} | _] = rules), do: rules
  def _ensure_root(rules) do
    [%{dest: root_symbol} | _] = rules
    [
      %Rule{dest: :Z, symbols: [:_Z, :"$"]},
      %Rule{dest: :_Z, symbols: [root_symbol]}
      | rules
    ]
  end

  def _put_final_state(%__module__{states: states} = sm) do
    states
    |> Enum.filter(fn
      {_, %State{parts: [part]}} ->
        StatePart.is_final(part)
      _ ->
        false
    end)
    |> case do
      [{_, %{id: id}}] ->
        put_in(sm.final_state, id)
    end
  end


  def _add_reduce(%__MODULE__{states: states, rules: rules} = sm) do
    states =
      states
      |> Enum.map(fn {k, v} -> {k, State.add_reduce(v, rules)} end)
      |> Enum.into(%{})

    put_in(sm.states, states)
  end

  def _add_transitions(%__MODULE__{states: states, rules: rules} = sm) do
    states =
      states
      |> Enum.reduce(states, fn {_id, state}, states ->
        State.find_transitions(state, rules)
        |> Enum.reduce(states, fn {symbol, new_state}, states ->
          {states, target_id} = _add_state(states, new_state)
          state = Map.get(states, state.id)

          state = if is_terminal(symbol) do
            put_in(
              state.rules,
              Map.put(state.rules, symbol, {:shift, target_id}))
          else
            put_in(
              state.goto,
              Map.put(state.goto, symbol, target_id))
          end
          Map.put(states, state.id, state)
        end)
      end)
    Map.put(sm, :states, states)
    |> case do
      ^sm -> sm
      new_sm -> new_sm |> _add_transitions()
    end
  end

  def _add_state(states, state) do
    states
    |> Map.values()
    |> Enum.filter(fn %{parts: parts} -> parts == state.parts end)
    |> case do
      [existing] ->
        {states, existing.id}
      [] ->
        new_id = _find_next_id(states)
        state = Map.put(state, :id, new_id)
        states = Map.put(states, new_id, state)
        {states, new_id}
    end
  end

  def _find_next_id(states) do
    max =
      states
      |> Map.keys()
      |> Enum.max()
    max + 1
  end

  def print(%__MODULE__{states: states}) do
    states
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn id -> Map.get(states, id) end)
    |> Enum.map(fn state ->
      State.print(state)
    end)
  end

  def print_table(%__MODULE__{rules: rules, states: states}) do
    rules
    |> Enum.map(fn rule ->
      IO.puts "#{rule.id}  #{rule.dest} <- #{inspect rule.symbols}"
    end)
    IO.puts ""

    terminals = Rule.all_terminals(rules)
    non_terminals = Rule.all_non_terminals(rules)

    header1 = terminals
             |> Enum.map(fn s -> String.pad_leading("#{s}", 4, " ") end)
             |> Enum.join(" | ")
    header2 = non_terminals
             |> Enum.map(fn s -> String.pad_leading("#{s}", 4, " ") end)
             |> Enum.join(" | ")

    # print header
    header = "      | #{header1} | #{header2}"
    IO.puts header

    # print states
    states
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn key -> states |> Map.get(key) end)
    |> Enum.map(fn state ->
      actions =
        terminals
        |> Enum.map(fn sym ->
          state.rules
          |> Map.get(sym)
          |> case do
            {:shift, to} -> String.pad_leading("s#{to}", 4, " ")
            {:reduce, to} -> String.pad_leading("r#{to}", 4, " ")
            :accept -> String.pad_leading("✓", 4, " ")
            _ -> "    "
          end
        end)
        |> Enum.join(" | ")
      gotos =
        non_terminals
        |> Enum.map(fn sym ->
          state.goto
          |> Map.get(sym)
          |> case do
            nil -> "    "
            to -> String.pad_leading("#{to}", 4, " ")
          end
        end)
        |> Enum.join(" | ")

      IO.puts String.pad_leading("", String.length(header), "-")
      IO.puts "#{String.pad_leading("#{state.id}", 4, " ")}  | #{actions} | #{gotos}"
    end)
  end

  def generate_graph(%__MODULE__{} = sm, file \\ "sm.png") do
    dot = to_dot(sm)
    File.write("/tmp/sm.dot", dot)
    {out, 0} = System.cmd("dot", ["/tmp/sm.dot", "-Tpng"])
    File.write(file, out)
  end

  def to_dot(%__MODULE__{states: states}) do
    states_dot =
      states
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn id -> Map.get(states, id) end)
      |> Enum.map(fn state ->
        State.to_dot(state)
      end)

    transitions =
      states
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn id -> Map.get(states, id) end)
      |> Enum.map(fn state ->
        State.to_dot_transitions(state)
      end)


    """
    digraph {
      #{states_dot}
      #{transitions}
    }
    """
  end
end
