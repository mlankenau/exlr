defmodule ExLR.ExampleCLikeTest do
  use ExUnit.Case
  use ExLR

  lr skip_whitespaces: true do
    Program <- Program + TopLevel
    Program <- TopLevel

    TopLevel <- Function
    TopLevel <- Declaration

    Function <- Type + :text + "(" + Arguments + ")" + "{" + FunctionContent + "}"   =
      fn [type, name, _, args, _, _, body, _] -> {:fun, type, name, args, body} end

    Arguments <- Argument + "," + Arguments     = fn [a, _ , args] -> [a | args] end
    Arguments <- Argument                       = fn [a] -> [a] end
    Argument <- Type + :text                    = fn [t, name] -> {:arg, t, name} end

    FunctionContent <- Declaration

    Declaration <- Type + :text + ";" = fn [type, name, _] -> {:declare, type, name} end
    Type <- Type + "*" = fn [t, _] -> {:ptr, t} end
    Type <- "int" = fn _ -> :int end
    Type <- "char" = fn _ -> :char end
  end

  test "simple declaration" do
    code = "int i;"
    assert parse(code) == {:ok, {:declare, :int, "i"}}
  end

  test "function" do
    code = """
    int main(char* argv) {
      int i;
    }
    """
    assert parse(code) ==  {:ok, {
      :fun,
      :int,
      "main",
      [
        {:arg, {:ptr, :char}, "argv"}
      ],
      {:declare, :int, "i"}
    }}
  end
end
