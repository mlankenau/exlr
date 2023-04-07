defmodule ExLR.Lexer.Symbol do
  def is_terminal(:"$"), do: true
  def is_terminal(b) when is_binary(b), do: true
  def is_terminal(a) do
    a
    |> Atom.to_string
    |> case do
      << f :: utf8 >> <> _ ->
        f >= ?a and f <= ?z
    end
  end
end
