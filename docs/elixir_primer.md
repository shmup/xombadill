# Elixir Primer

## Core Concepts

- **Functional language** built on Erlang VM (BEAM)
- **Immutable data** - values never change
- **Pattern matching** as primary control flow
- **Process-oriented** concurrency (not OS threads)
- **Fault tolerance** via supervision trees


## Syntax Basics
```elixir
# Functions
def add(a, b), do: a + b

# Anonymous functions
add = fn a, b -> a + b end

# Pipe operator
"hello" |> String.upcase() |> String.reverse()

# Pattern matching
[head | tail] = [1, 2, 3]  # head = 1, tail = [2, 3]
```

## Data Types

- **Atoms**: `:ok`, `:error` (symbols)
- **Tuples**: `{:ok, result}`, `{:error, reason}`
- **Lists**: `[1, 2, 3]` (linked lists)
- **Maps**: `%{key: "value"}`
- **Structs**: `%User{name: "John"}`

## Concurrency Model

- **Processes**: Lightweight (2KB), isolated memory
- **Message passing**: `send(pid, message)` and `receive`
- **No shared state** between processes
- **OTP**: Framework for building fault-tolerant apps

## Key Paradigms

- **"Let it crash"** philosophy
- **Supervisors** restart failed processes
- **GenServer** for stateful processes
- **Pattern matching** for control flow
- **Protocols** for polymorphism

## Project Structure

- **Mix**: Build tool
- **Modules**: Code organization units
- **Behaviours**: Interface definitions
- **Applications**: Standalone or composable units
- **Umbrella projects**: Multi-app projects
