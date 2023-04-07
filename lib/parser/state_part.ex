defmodule ExLR.Parser.StatePart do
  defstruct rem: [],
            rule: nil

  def build_initial(%{symbols: symbols} = rule) do
    %__MODULE__{
      rem: symbols,
      rule: rule
    }
  end

  def next_symbol(%{rem: [:"$"]}), do: nil
  def next_symbol(%{rem: [s | _]}), do: s
  def next_symbol(%{rem: []}), do: nil

  def slide_one_symbol(%__MODULE__{rem: []}), do: nil
  def slide_one_symbol(%__MODULE__{rem: [_ | rem]} = part) do
    %__MODULE__{
      part |
      rem: rem
    }
  end

  def to_string(%__MODULE__{rem: rem, rule: %{dest: dest, symbols: symbols}}) do
    part =
      symbols
      |> Enum.with_index()
      |> Enum.map(fn {s, i} ->
        if i == length(symbols) - length(rem) do
          ". #{s}"
        else
          "#{s}"
        end
      end)
      |> Enum.join(" ")

    part = if rem == [], do: "#{part} .", else: part
    "#{dest} -> #{part}"
  end
  def is_final(%__MODULE__{rem: [:"$"], rule: %{dest: :Z}}), do: true
  def is_final(%__MODULE__{}), do: false
end
