defmodule ClusterConnectSmartcell.MixProject do
  use Mix.Project

  def project do
    [
      app: :cluster_connect_smartcell,
      version: "0.0.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Package
      description: description(),
      package: package(),
      # Docs
      name: "ClusterConnect Smartcell",
      source_url: "https://github.com/zoten/cluster_connect_smartcell",
      homepage_url: "https://github.com/zoten/cluster_connect_smartcell",
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ClusterConnectSmartcell.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:kino, "~> 0.6.1"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_images/1]
    ]
  end

  defp package do
    [
      name: "cluster_connect_smartcell",
      maintainers: ["Luca Dei Zotti"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/zoten/cluster_connect_smartcell"}
    ]
  end

  defp description do
    "A livebook smartcell to connect to nodes and send commands from livebook and use locally installed goodies"
  end

  defp docs,
    do: [
      # The main page in the docs
      main: "ClusterConnectSmartcell",
      # logo: "path/to/logo.png",
      extras: [
        "README.md"
      ]
    ]

  defp copy_images(_) do
    File.cp_r("assets", "doc/assets", fn source, destination ->
      IO.gets("Overwriting #{destination} by #{source}. Type y to confirm. ") == "y\n"
    end)
  end
end
