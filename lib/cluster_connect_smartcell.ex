defmodule ClusterConnectSmartcell do
  @moduledoc """
  #{File.read!("README.md")}
  """

  use Kino.JS, assets_path: "lib/assets/cluster_connect_smartcell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "OTP Connect"

  @impl true
  def init(attrs, ctx) do
    root_fields = %{
      "target_node" => attrs["target_node"] || "",
      "target_node_bound" => attrs["target_node_bound"] || "",
      "erlang_cookie" => attrs["erlang_cookie"] || "",
      "erlang_cookie_bound" => attrs["erlang_cookie_bound"] || "",
      "module" => attrs["module"] || "",
      "function" => attrs["function"] || "",
      "arguments" => attrs["arguments"] || "",
      "bind_result" => Kino.SmartCell.prefixed_var_name("rpc_result", attrs["bind_result"])
    }

    ctx =
      ctx
      |> assign(root_fields: root_fields)
      |> assign(node_bounds: %{})
      |> assign(cookie_bounds: %{})

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    # Called first time the client connects, gives initial state
    payload = %{
      root_fields: ctx.assigns.root_fields,
      node_bounds: ctx.assigns.node_bounds,
      cookie_bounds: ctx.assigns.cookie_bounds
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
      "target_node_bound" => target_node_bound,
      "erlang_cookie" => erlang_cookie,
      "erlang_cookie_bound" => erlang_cookie_bound,
      "module" => module,
      "function" => function,
      "arguments" => arguments,
      "bind_result" => bind_result
    } = attrs

    target_node = target_node |> get_target_node(target_node_bound) |> String.to_atom()
    erlang_cookie = erlang_cookie |> get_erlang_cookie(erlang_cookie_bound) |> String.to_atom()

    quote do
      unquote(quoted_var(bind_result)) =
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

  # implementations to find out possible bindings

  @impl true
  def handle_info({:scan_binding_result, data}, ctx) do
    ctx = assign(ctx, data_options: data)

    broadcast_event(ctx, "update_binding", %{"bindings" => data})

    {:noreply, ctx}
  end

  @doc """
  Try to identify possible autocompletion targets

  possible nodes: atoms contianing "@" character
  possible secrets: atoms
  """
  @impl true
  def scan_binding(pid, binding, _env) do
    possible_nodes =
      binding
      |> Enum.filter(fn {_key, value} -> is_atom(value) end)
      |> Enum.filter(fn {_key, value} -> value |> Atom.to_string() |> String.contains?("@") end)
      |> Enum.into(%{})

    possible_secrets =
      binding
      |> Enum.filter(fn {_key, value} -> is_atom(value) end)
      |> Enum.into(%{})

    data = %{
      possible_nodes: possible_nodes,
      possible_secrets: possible_secrets
    }

    send(pid, {:scan_binding_result, data})
  end

  # defp to_select_pair({key, value}) when is_atom(key), do: {Atom.to_string(key), value}
  # defp to_select_pair({key, value}), do: {key, value}

  # NOTE: this function needs to remain public, so it can be called by generated code
  # Candidate for refactor :)
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

  # NOTE: this function needs to remain public, so it can be called by generated code
  # Candidate for refactor :)
  def do_execute_remote_command(_target_node, _module, _function, _arguments),
    do: {:ok, :no_command}

  # Privates
  defp quoted_var(value) when is_binary(value), do: {String.to_atom(value), [], nil}
  defp quoted_var(value) when is_atom(value), do: {value, [], nil}

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

  defp get_target_node("", target_node_bound), do: target_node_bound
  defp get_target_node(target_node, ""), do: target_node
  defp get_target_node(_target_node, target_node_bound), do: target_node_bound

  defp get_erlang_cookie("", erlang_cookie_bound), do: erlang_cookie_bound
  defp get_erlang_cookie(erlang_cookie, ""), do: erlang_cookie
  defp get_erlang_cookie(_target_node, erlang_cookie_bound), do: erlang_cookie_bound
end
