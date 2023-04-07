defmodule ExLR do
  alias ExLR.Parser.StateMachine
  alias ExLR.Lexer.Lexer

  defmacro __using__(_opts) do
    quote do
      import ExLR
      require ExLR
    end
  end

  defmacro lr(opts \\ [], do: body) do
    {:__block__, _, list} = body

    rules =
      list
      |> Enum.map(fn
        {:<-, _, [ {_, _, [dest]}, {:=, _, [ symbols, fun ]} ]} ->
          symbols = _parse_symbols(symbols)
                    |> List.flatten
                    |> Enum.reverse()
          %ExLR.Parser.Rule{dest: dest, symbols: symbols, reduce: fun}

        {:<-, _, [ {_, _, [dest]}, symbols ]} ->
          symbols = _parse_symbols(symbols)
                    |> List.flatten
                    |> Enum.reverse()
          %ExLR.Parser.Rule{dest: dest, symbols: symbols}

        invalid ->
          IO.inspect invalid
          raise "Failed to read rule: #{Macro.to_string invalid}"
      end)

    sm = StateMachine.build(rules)

    terminals = ExLR.Parser.Rule.all_terminals(rules)

    if Keyword.get(opts, :print_table) do
      StateMachine.print_table(sm)
    end

    if Keyword.get(opts, :generate_graph) do
      StateMachine.generate_graph(sm)
    end

    shifts_reduces =
      sm.states
      |> Enum.reduce(nil, fn {_k, state}, acc ->
        state.rules
        |> Enum.reduce(acc, fn
          {source_sym, {:shift, target}}, acc ->
            quote do
              unquote(acc)

              def parse([unquote(state.id) | _] = stack, [{unquote(source_sym), _, _} = sym | rem] = input) do
                parse([unquote(target), sym | stack], rem)
              end
            end
          {source_sym, {:reduce, rule_id}}, acc ->
            [rule] = sm.rules |> Enum.filter(& &1.id == rule_id)
            num_syms = length(rule.symbols)

            reduce_fun = if rule.reduce do
              rule.reduce
            else
              # default reduce function (if nothing defined)
              quote do
                fn
                  # if we have a single symbol in the list, we return the symbol
                  [s] -> s

                  # otherwise, we return the list
                  a -> a
                end
              end
            end

            quote do
              unquote(acc)

              def parse([unquote(state.id) | _] = stack, [{unquote(source_sym), _, _} | rem] = input) do
                extract = stack |> Enum.take(2*unquote(num_syms))
                          |> Enum.drop_every(2)
                          |> Enum.map(fn {_, d, _} -> d end)
                          |> Enum.reverse()

                [state_id | _] = new_stack = stack |> Enum.drop(2*unquote(num_syms))
                target_state = _goto_for(state_id, unquote(rule.dest))
                res = unquote(reduce_fun).(extract)
                parse([target_state, {unquote(rule.dest), res, nil} | new_stack], input)
              end
            end
        end)
      end)

    gotos =
      sm.states
      |> Enum.reduce(nil, fn {_k, state}, acc ->
        state.goto
        |> Enum.reduce(acc, fn {sym, target}, acc ->
          quote do
            unquote(acc)
            def _goto_for(unquote(state.id), unquote(sym)), do: unquote(target)
          end
        end)
      end)

    lexer =
      quote do
        lexer =
        unquote(terminals)
        |> Enum.reduce(Lexer.init(unquote(opts)), fn t, acc ->
          terminal(t)
          |> case do
            nil -> Lexer.add_terminal(acc, t)
            t -> Lexer.add_terminal(acc, t)
          end
        end)
      end


    generated_code =
      quote do
        alias ExLR.Lexer

        unquote(gotos)

        def parse([unquote(sm.final_state), {_, data, _} | _] = stack, input) do
          {:ok, data}
        end

        unquote(shifts_reduces)

        def parse([state | _], [sym | _]), do: {:error, :unexpected, sym}

        def parse(symbol_list) when is_list(symbol_list) do
          parse([0], symbol_list)
        end

        def lex(str) when is_binary(str) do
          lexer = unquote(lexer)
          Lexer.scan(str, lexer)
        end

        def parse(str) when is_binary(str) do
          lexer = unquote(lexer)

          Lexer.scan(str, lexer)
          |> case do
            {:ok, symbols} ->
              parse(symbols)
            err ->
              err
          end
        end
        def terminal(_), do: nil
      end

    if Keyword.get(opts, :store_generated_code) do
      File.write("lr_code.ex", Macro.to_string(generated_code))
    end

    generated_code
  end

  defmacro terminal(name, opts) do
    min = Keyword.get(opts, :min, 1)
    max = Keyword.get(opts, :max, 99999999)
    cond do
      Keyword.get(opts, :chars) ->
        chars = Keyword.get(opts, :chars)
        quote do
          def terminal(unquote(name)) do
            ExLR.Lexer.Terminal.gen_terminal(unquote(name), unquote(chars), unquote(min), unquote(max))
          end
        end

      Keyword.get(opts, :stop_chars) ->
        chars = Keyword.get(opts, :stop_chars)
        quote do
          def terminal(unquote(name)) do
            ExLR.Lexer.Terminal.gen_terminal_stop_chars(unquote(name), unquote(chars), unquote(min), unquote(max))
          end
        end

      true ->
        raise "terminal #{name}, missing argument chars or stop_chars"
    end
  end

  def _parse_symbols(a) when is_atom(a), do: [a]
  def _parse_symbols(a) when is_binary(a), do: [a]
  def _parse_symbols({:__aliases__, _, [a]}), do: [_parse_symbols(a)]
  def _parse_symbols({:+, _, [a, b]}), do: [_parse_symbols(b), _parse_symbols(a)]
end
