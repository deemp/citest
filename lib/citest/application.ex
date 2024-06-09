defmodule Citest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CitestWeb.Telemetry,
      # Start the Ecto repository
      Citest.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Citest.PubSub},
      # Start Finch
      {Finch, name: Citest.Finch},
      # Start the Endpoint (http/https)
      CitestWeb.Endpoint
      # Start a worker by calling: Citest.Worker.start_link(arg)
      # {Citest.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Citest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CitestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
