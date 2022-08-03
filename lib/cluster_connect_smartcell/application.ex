defmodule ClusterConnectSmartcell.Application do
  @moduledoc false

  use Application

  alias Kino.SmartCell

  @impl true
  def start(_type, _args) do
    SmartCell.register(ClusterConnectSmartcell)
    children = []
    opts = [strategy: :one_for_one, name: ClusterConnectSmartcell.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
