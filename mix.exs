defmodule MonoRepo.MixProject do
  use Mix.Project

  def project do
    [
      app: :mono_repo,
      name: "MonoRepo",
      version: "0.2.0",
      elixir: "~> 1.9",
      description: description(),
      package: package(),
      source_url: github_link(),
      homepage_url: github_link(),
      deps: deps()
    ]
  end

  def package do
    [
      maintainers: ["Alexander Ulyev"],
      licenses: ["MIT"],
      links: links()
    ]
  end

  defp links do
    %{
      "GitHub" => github_link()
    }
  end

  defp github_link do
    "https://github.com/alexander-uljev/mono_repo"
  end

  defp description do
    "A library to work with mono repositories."
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21.0", only: :dev, runtime: false}
    ]
  end
end
