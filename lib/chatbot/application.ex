defmodule Chatbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChatbotWeb.Telemetry,
      # Start the Ecto repository
      Chatbot.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chatbot.PubSub},
      # Start Finch
      {Finch, name: Chatbot.Chatbot.Finch},
      # Start the Endpoint (http/https)
      ChatbotWeb.Endpoint
      # Start a worker by calling: Chatbot.Worker.start_link(arg)
      # {Chatbot.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
