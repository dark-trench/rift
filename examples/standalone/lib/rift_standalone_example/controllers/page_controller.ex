defmodule RiftStandaloneExample.PageController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias RiftStandaloneExample.Resolver

  import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1]

  def home(conn, _params) do
    actor = Resolver.resolve_actor(conn)
    case_types = Resolver.resolve_case_types(actor)
    actor_label = escape(Resolver.resolve_actor_label(actor.id))
    titles = case_types |> Enum.map_join(", ", & &1.title()) |> escape()

    html(conn, """
    <!doctype html>
    <html>
      <head><title>Rift standalone example</title></head>
      <body>
        <h1>Rift standalone example</h1>
        <p>Actor: #{actor_label}</p>
        <p>Case types: #{titles}</p>
      </body>
    </html>
    """)
  end

  defp escape(value) do
    value
    |> html_escape()
    |> safe_to_string()
  end
end
