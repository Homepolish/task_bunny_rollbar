defmodule TaskBunnySentry.Mixfile do
  use Mix.Project

  @version "0.1.2"
  @description "TaskBunny job failure backend that reports the error to Sentry"

  def project do
    [
      app: :task_bunny_sentry,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        extras: ["README.md"], main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/homepolish/task_bunny_sentry"
      ],
      description: @description,
      package: package()
    ]
  end

  def application do
    [
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:task_bunny, "~> 0.2"},
      {:sentry, "~> 6.0.0"},

      # dev
      {:ex_doc, "~> 0.14", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev}
    ]
  end

  defp package do
    [
      name: :task_bunny_sentry,
      files: [
        "mix.exs", "README.md", "LICENSE.md", # Project files
        "lib"
      ],
      maintainers: [
        "Elliott Hilaire",
        "Francesco Grammatico",
        "Ian Luites",
        "Ricardo Perez",
        "Tatsuya Ono",
        "Dylan Reile",
        "Erik Reedstrom"
      ],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/homepolish/task_bunny_sentry"}
    ]
  end
end
