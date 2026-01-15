defmodule DocSpec.MixProject do
  use Mix.Project

  @version "0.1.0"
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

  defp dialyzer_config(:test), do: [plt_add_apps: [:ex_unit]]
  defp dialyzer_config(_), do: []

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nldoc_spec, "~> 3.1"},
      {:nldoc_util, "~> 1.0"},
      {:nldoc_conversion_reader_docx, "~> 1.1"},

      # Defining data structures
      {:typed_struct, "~> 0.3.0"},

      # JSON Parsing
      {:jason, "~> 1.4"},

      # Testing
      {:nldoc_test, "~> 3.0", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:mimic, "~> 2.1", only: :test},

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
