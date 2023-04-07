# ExLR

ExLR is a LR parser written in Elixir language.

## Installation

The package can be installed
by adding `exlr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exlr, github: "mlankenau/exlr"}
  ]
end
```

## How to use the parser

The parse is defined by a simple DSL:


```elixir
defmodule MyParser do
  use ExLR

  lr do
    # put the rules here
  end
end
```

The lr macro has a couple of options:
- skip_whitespaces: whitespaces between terminals are ignored
- print_table=true: print the lr parser table
- generate_graph=true: generate a png with the state machine (dot as to be installed)

The DSL generates a parse function so it can be used like this:

```elixir
MyParser.parse("...")
```

ExLR supports to define the terminals in place:

```elixir
lr do
  S <- "foo" + S
  S <- S
end
```

Reduction functions can be placed behind the rules:

```elixir
lr do
  S <- "foo" + S  = fn [f, s] -> [f | s] end
  S <- S
end
```

These implicit terminals are supported:

- Strings
- :ws      (whitespaces)
- :integer (e.g. 123)
- :text    (e.g. foo)
- :quoted_text (e.g. "foo")

Terminals can also be defined with the DSL:

```elixir
terminal :zip_code, chars: ?0..?9, min: 4, max: 5
lr do
  Address <- :zip_code + :ws + City
  City <- :text
end
```

See the example test-cases for more documentation.

### License ###
(The MIT License)

Copyright (c) 2023 Marcus Lankenau

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
