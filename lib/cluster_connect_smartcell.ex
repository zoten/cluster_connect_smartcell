defmodule ClusterConnectSmartcell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/cluster_connect_smartcell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "OTP Connect"

  @impl true
  def init(attrs, ctx) do
    root_fields = %{
      "target_node" => attrs["target_node"] || "",
      "erlang_cookie" => attrs["erlang_cookie"] || "",
      "module" => attrs["module"] || "",
      "function" => attrs["function"] || "",
      "arguments" => attrs["arguments"] || ""
    }

    {:ok, assign(ctx, root_fields: root_fields)}
  end

  @impl true
  def handle_connect(ctx) do
    # Called first time the cliet connects, gives initial state
    payload = %{
      root_fields: ctx.assigns.root_fields
    }

    {:ok, payload, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.root_fields
  end

  @impl true
  def to_source(attrs) do
    %{
      "target_node" => target_node,
      "erlang_cookie" => erlang_cookie,
      "module" => module,
      "function" => function,
      "arguments" => arguments
    } = attrs

    target_node = String.to_atom(target_node)
    erlang_cookie = String.to_atom(erlang_cookie)

    quote do
      with {:cookie, true} <-
             {:cookie, :erlang.set_cookie(unquote(erlang_cookie))},
           {:connect, true} <-
             {:connect,
              unquote(target_node)
              |> :net_kernel.connect_node()},
           {:monitor, :ok} <- {:monitor, :net_kernel.monitor_nodes(true)},
           nodes <- Node.list(:connected),
           {:command, {:ok, result}} <-
             {:command,
              ClusterConnectSmartcell.do_execute_remote_command(
                unquote(target_node),
                unquote(module),
                unquote(function),
                unquote(arguments)
              )} do
        %{"result" => result, "nodes" => nodes}
      else
        {step, res} when step in [:cookie, :connect, :command, :monitor] ->
          %{"outcome" => false} |> Map.put(Atom.to_string(step), res)

        error ->
          %{"outcome" => false, "error" => error}
      end
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  # Event Handlers
  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    parsed_value = parse_value(field, value)
    ctx = update(ctx, :root_fields, &Map.put(&1, field, parsed_value))
    broadcast_event(ctx, "update_root", %{"fields" => %{field => parsed_value}})

    {:noreply, ctx}
  end

  def do_execute_remote_command(target_node, module, function, arguments)
      when is_binary(module) and byte_size(module) > 0 and
             is_binary(function) and byte_size(function) > 0 and
             is_binary(arguments) and byte_size(arguments) > 0 do
    module = module |> normalize_module_name() |> String.to_atom()
    function = String.to_atom(function)
    # pass a list for now
    {arguments, _bindings} = arguments |> Code.eval_string() |> parse_evaluated_arguments!()
    :erpc.call(target_node, module, function, arguments)
  rescue
    error -> error
  end

  def do_execute_remote_command(_target_node, _module, _function, _arguments),
    do: {:ok, :no_command}

  # Privates
  defp parse_value(_field, value), do: value

  defp normalize_module_name(module) do
    if String.starts_with?(module, "Elixir.") do
      module
    else
      "Elixir.#{module}"
    end
  end

  defp parse_evaluated_arguments!({arguments, bindings}) when is_list(arguments),
    do: {arguments, bindings}

  defp parse_evaluated_arguments!({arguments, _bindings}),
    do: raise("Arguments should be a list, got #{inspect(arguments)}")
end
