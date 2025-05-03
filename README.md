# Xombadill

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `xombadill` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:xombadill, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/xombadill>.


## Initial Creation on Fedora

```bash
dnf install erlang elixir
mix new xombadill --sup
```

```bash
git clone https://github.com/elixir-lsp/elixir-ls.git ~/.elixir-ls
cd ~/.elixir-ls
mix deps.get && mix compile && MIX_ENV=prod mix elixir_ls.release2 -o release
```

```
:CocConfig

Add:

{
  "elixir.pathToElixirLS": "~/.elixir-ls/release/language_server.sh"
}
```
