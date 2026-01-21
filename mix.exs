defmodule DocSpec.MixProject do
  use Mix.Project

  @version "1.1.0"
  @source_url "https://github.com/docspec/docspec-ex"

  def project do
    [
      app: :docspec,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer_config(Mix.env()),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      test_coverage: [tool: ExCoveralls],
      test_ignore_filters: [~r/test\/snapshots\//],
      escript: escript(),

      # Docs
      name: "DocSpec",
      description: "DocSpec core library",
      source_url: @source_url,
      docs: docs(),
      package: package()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      licenses: ["EUPL-1.2"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp dialyzer_config(:test),
    do: [plt_add_apps: [:ex_unit], warnings_as_errors: true]

  defp dialyzer_config(_),
    do: [warnings_as_errors: true]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp escript do
    [
      main_module: DocSpec.CLI,
      name: "docspec"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Schema definitions with Ecto types
      {:ecto, "~> 3.12"},
      {:typed_ecto_schema, "~> 0.4"},
      {:polymorphic_embed, "~> 5.0"},

      # Defining data structures
      {:typed_struct, "~> 0.3.0"},

      # JSON Parsing
      {:jason, "~> 1.4"},

      # HTML Parsing
      {:floki, "~> 0.38"},

      # XML Parsing
      {:saxy, "~> 1.6"},
      {:simple_form, "~> 1.0"},

      # Utilities
      {:useful, "~> 1.0"},
      {:recase, "~> 0.9"},
      {:html_entities, "~> 0.5"},
      {:temp, "~> 0.4"},

      # Testing
      {:excoveralls, "~> 0.18", only: :test},
      {:mimic, "~> 2.1", only: :test},
      {:briefly, "~> 0.5", only: :test},
      {:exposure, "~> 1.1", only: [:dev, :test], runtime: false},

      # Linting & static analysis
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Dependency auditing
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Docs
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end
end
