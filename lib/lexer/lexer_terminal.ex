defmodule ExLR.Lexer.Terminal do
  defstruct symbol: nil,
            scan: nil,
            process: nil

  def gen_terminal(name, possible_chars, min, max) do
    possible_chars = _prep_char_list(possible_chars)
                     |> List.flatten()

    scan = fn char, num ->
      valid_char = char in possible_chars

      if valid_char do
        case num do
          nil ->
            {:match, 1}
          num when num >= max ->
            :no_match_completed
          num ->
            {:match, num + 1}
        end
      else
        if not is_nil(num) and num >= min do
          :no_match_completed
        else
          :no_match
        end
      end
    end

    %__MODULE__{
      symbol: name,
      scan: scan,
      process: & &1
    }
  end

  def gen_terminal_stop_chars(name, stop_chars, min, max) do
    stop_chars = _prep_char_list(stop_chars)
                     |> List.flatten()

    scan = fn char, num ->
      valid_char = char not in stop_chars

      if valid_char do
        case num do
          nil ->
            {:match, 1}
          num when num >= max ->
            :no_match_completed
          num ->
            {:match, num + 1}
        end
      else
        if not is_nil(num) and num >= min do
          :no_match_completed
        else
          :no_match
        end
      end
    end

    %__MODULE__{
      symbol: name,
      scan: scan,
      process: & &1
    }
  end

  def _prep_char_list(%Range{} = range), do: Enum.into(range, [])
  def _prep_char_list(list) when is_list(list), do: Enum.map(list, &_prep_char_list/1)
  def _prep_char_list(i) when is_integer(i), do: i

  def generate(<< first_char :: utf8 >> <> rem_chars = s) do
    scan = fn
      ^first_char, nil ->
        # no state, lets init
        {:match, rem_chars}

      char, << char :: utf8 >> <> rem ->
        {:match, rem}

      _, "" ->
        :no_match_completed

      _, _ ->
        :no_match
    end

    %__MODULE__{
      symbol: s,
      scan: scan,
      process: & &1
    }
  end
  def generate(:integer) do
    scan = fn
      char, _ when char in [?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9]->
        {:match, :inside_integer}

      _, nil ->
        :no_match

      _, _ ->
        :no_match_completed
    end

    %__MODULE__{
      symbol: :integer,
      scan: scan,
      process: &String.to_integer/1
    }
  end
  def generate(:text) do
    scan = fn
      c, _ when c in (?a..?z) or c in (?A..?Z) or c in (?0..?9) ->
        # no state, lets init
        {:match, true}
      _, nil ->
        # no state, lets init
        :no_match
      _, true ->
        # no state, lets init
        :no_match_completed
    end

    %__MODULE__{
      symbol: :text,
      scan: scan,
      process: & &1
    }
  end
  def generate(:quoted_text) do
    scan = fn
      ?", nil ->
        # no state, lets init
        {:match, true}
      _, nil ->
        # no state, lets init
        :no_match

      ?", true ->
        {:match, false}
      _, true ->
        {:match, true}

      _, false ->
        :no_match_completed
    end

    %__MODULE__{
      symbol: :quoted_text,
      scan: scan,
      process: &String.slice(&1, 1, String.length(&1) - 2)
    }
  end

  @whitespaces [32, ?\t, ?\n, ?\r]
  def generate(:ws) do
    scan = fn
      c, _ when c in @whitespaces ->
        # no state, lets init
        {:match, true}

      _, _ ->
        :no_match_completed
    end

    %__MODULE__{
      symbol: :ws,
      scan: scan,
      process: & &1
    }
  end
end
