defmodule ExLR.Lexer.Lexer do
  alias ExLR.Lexer.Terminal
  defstruct opts: %{}, terminals: [], active: [], buffer: "", current_pos: {0, 0}, sym_pos: {0, 0}

  def init(opts \\ []), do: %__MODULE__{opts: opts |> Enum.into(%{})}

  def add_terminal(lexer, %Terminal{} = t) do
    %__MODULE__{lexer | terminals: [t | lexer.terminals]}
  end
  def add_terminal(lexer, t) do
    t = ExLR.Lexer.Terminal.generate(t)
    %__MODULE__{lexer | terminals: [t | lexer.terminals]}
  end

  def scan(s, lexer) when is_binary(s) do
    lexer = put_in(lexer.terminals, lexer.terminals |> Enum.reverse)
    _scan_string(s, lexer)
    |> case do
      list when is_list(list) -> {:ok, list}
      err -> err
    end
  end

  @whitespaces [?\t, 0x20, ?\n, ?\r]

  def _scan_string(<< c :: utf8 >> <> rem = input, lexer) do
    _scan(c, lexer)
    |> case do
      {:continue, lexer} ->
        lexer = _change_pos(c, lexer)
        _scan_string(rem, lexer)
      {:out, sym, lexer} ->
        _scan_string(input, lexer)
        |> case do
          rem when is_list(rem) -> [sym | rem]
          err -> err
        end
      :no_match ->
        {:error, :unknown_symbol, lexer.sym_pos, String.slice(input, 0, 10)}
    end
  end
  def _scan_string("", lexer) do
    _scan(0, lexer)
    |> case do
      {:out, sym, _lexer} ->
        [sym, {:"$", nil, lexer.sym_pos}]
      :no_match ->
        [{:"$", nil, lexer.sym_pos}]
    end
  end

  def _change_pos(?\n, %{current_pos: {line, _pos}} = lexer) do
    %__MODULE__{lexer | current_pos: {line+1, 0}}
  end
  def _change_pos(_, %{current_pos: {line, pos}} = lexer) do
    %__MODULE__{lexer | current_pos: {line, pos+1}}
  end

  # no active terminals
  def _scan(c, %__MODULE__{terminals: terminals, active: []} = scanner) do
    terminals
    |> Enum.map(fn
      t -> {t, t.scan.(c, nil)}
    end)
    |> Enum.map(fn
      {_, :no_match} -> nil
      {t, {:match, state}} -> {t, state}
      {_, :no_match_completed} -> nil
    end)
    |> Enum.filter(& &1)
    |> case do
      [] ->
        if c in @whitespaces and scanner.opts[:skip_whitespaces] do
          {:continue, put_in(scanner.sym_pos, scanner.current_pos)}
        else
          # we found no valid symbol
          :no_match
        end
      list ->
        {:continue, %__MODULE__{scanner | active: list, buffer: << c >>, sym_pos: scanner.current_pos}}
    end
  end

  # active terminals
  def _scan(c, %__MODULE__{active: active} = scanner) do
    results =
      active
      |> Enum.map(fn
        {t, state} -> {t, t.scan.(c, state)}
      end)

    results
    |> Enum.map(fn
      {t, {:match, state}} -> {t, state}
      _ -> nil
    end)
    |> Enum.filter(& &1)
    |> case do
      [] ->
        completed =
          results
          |> Enum.filter(fn
            {t, :no_match_completed} -> t
            _ -> nil
          end)
          |> Enum.filter(& &1)

        _scan_end_of_terminal(scanner, completed)

      list ->
        {:continue, %__MODULE__{scanner | active: list, buffer: scanner.buffer <> << c >>}}
    end
  end

  def _scan_end_of_terminal(_scanner, []) do
    :no_match
  end
  def _scan_end_of_terminal(%{buffer: buffer} = scanner, [{%Terminal{symbol: symbol, process: process}, _value} | _]) do
    val = process.(buffer)
    {:out, {symbol, val, scanner.sym_pos}, %__MODULE__{scanner| buffer: "", active: []}}
  end

end
