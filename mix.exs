defmodule Xombadill.MixProject do
  use Mix.Project

  def project do
    [
      app: :xombadill,
      version: "0.1.0",
      elixir: "~> 1.16-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Xombadill.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:exirc, git: "https://github.com/shmup/exirc.git", branch: "main"},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false}
    ]
  end
end
