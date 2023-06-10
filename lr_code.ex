alias ExLR.Lexer

(
  (
    nil

    def _goto_for(0, :S) do
      1
    end
  )

  def _goto_for(0, :_Z) do
    2
  end
)

def parse([2, {_, data, _} | _] = stack, input) do
  {:ok, data}
end

(
  (
    (
      (
        (
          (
            (
              (
                nil

                def parse([0 | _] = stack, [{:integer, _, _} = sym | rem] = input) do
                  parse([3, sym | stack], rem)
                end
              )

              def parse([1 | _] = stack, [{:"$", _, _} | rem] = input) do
                extract =
                  stack
                  |> Enum.take(2 * 1)
                  |> Enum.drop_every(2)
                  |> Enum.map(fn {_, d, _} -> d end)
                  |> Enum.reverse()

                [state_id | _] = new_stack = stack |> Enum.drop(2 * 1)
                target_state = _goto_for(state_id, :_Z)

                res =
                  (fn
                     [s] -> s
                     a -> a
                   end).(extract)

                parse([target_state, {:_Z, res, nil} | new_stack], input)
              end
            )

            def parse([1 | _] = stack, [{"+", _, _} = sym | rem] = input) do
              parse([4, sym | stack], rem)
            end
          )

          def parse([3 | _] = stack, [{:"$", _, _} | rem] = input) do
            extract =
              stack
              |> Enum.take(2 * 1)
              |> Enum.drop_every(2)
              |> Enum.map(fn {_, d, _} -> d end)
              |> Enum.reverse()

            [state_id | _] = new_stack = stack |> Enum.drop(2 * 1)
            target_state = _goto_for(state_id, :S)
            res = (fn [a] -> a end).(extract)
            parse([target_state, {:S, res, nil} | new_stack], input)
          end
        )

        def parse([3 | _] = stack, [{"+", _, _} | rem] = input) do
          extract =
            stack
            |> Enum.take(2 * 1)
            |> Enum.drop_every(2)
            |> Enum.map(fn {_, d, _} -> d end)
            |> Enum.reverse()

          [state_id | _] = new_stack = stack |> Enum.drop(2 * 1)
          target_state = _goto_for(state_id, :S)
          res = (fn [a] -> a end).(extract)
          parse([target_state, {:S, res, nil} | new_stack], input)
        end
      )

      def parse([4 | _] = stack, [{:integer, _, _} = sym | rem] = input) do
        parse([5, sym | stack], rem)
      end
    )

    def parse([5 | _] = stack, [{:"$", _, _} | rem] = input) do
      extract =
        stack
        |> Enum.take(2 * 3)
        |> Enum.drop_every(2)
        |> Enum.map(fn {_, d, _} -> d end)
        |> Enum.reverse()

      [state_id | _] = new_stack = stack |> Enum.drop(2 * 3)
      target_state = _goto_for(state_id, :S)
      res = (fn [a, _, b] -> a + b end).(extract)
      parse([target_state, {:S, res, nil} | new_stack], input)
    end
  )

  def parse([5 | _] = stack, [{"+", _, _} | rem] = input) do
    extract =
      stack
      |> Enum.take(2 * 3)
      |> Enum.drop_every(2)
      |> Enum.map(fn {_, d, _} -> d end)
      |> Enum.reverse()

    [state_id | _] = new_stack = stack |> Enum.drop(2 * 3)
    target_state = _goto_for(state_id, :S)
    res = (fn [a, _, b] -> a + b end).(extract)
    parse([target_state, {:S, res, nil} | new_stack], input)
  end
)

def parse([state | _], [sym | _]) do
  {:error, :unexpected, sym}
end

def parse(symbol_list) when is_list(symbol_list) do
  parse([0], symbol_list)
end

def lex(str) when is_binary(str) do
  lexer =
    lexer =
    [:integer, "+"]
    |> Enum.sort(fn
      a, b when not is_binary(a) and is_binary(b) -> false
      a, b when is_binary(a) and not is_binary(b) -> true
      a, b -> Map.get(@terminal_prios, a) <= Map.get(@terminal_prios, b)
    end)
    |> Enum.reduce(Lexer.init(store_generated_code: true, skip_whitespaces: true), fn t, acc ->
      terminal(t)
      |> case do
        nil -> Lexer.add_terminal(acc, t)
        t -> Lexer.add_terminal(acc, t)
      end
    end)

  Lexer.scan(str, lexer)
end

def parse(str) when is_binary(str) do
  lexer =
    lexer =
    [:integer, "+"]
    |> Enum.sort(fn
      a, b when not is_binary(a) and is_binary(b) -> false
      a, b when is_binary(a) and not is_binary(b) -> true
      a, b -> Map.get(@terminal_prios, a) <= Map.get(@terminal_prios, b)
    end)
    |> Enum.reduce(Lexer.init(store_generated_code: true, skip_whitespaces: true), fn t, acc ->
      terminal(t)
      |> case do
        nil -> Lexer.add_terminal(acc, t)
        t -> Lexer.add_terminal(acc, t)
      end
    end)

  Lexer.scan(str, lexer)
  |> case do
    {:ok, symbols} -> parse(symbols)
    err -> err
  end
end

def terminal(_) do
  nil
end