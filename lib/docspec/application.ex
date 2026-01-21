defmodule DocSpec.Application do
  @moduledoc """
  OTP Application for DocSpec.

  When compiled with BURRITO_BUILD=1, invokes the CLI on start.
  When compiled as a library, starts an empty supervisor.
  """

  use Application

  # Compile-time flag: set BURRITO_BUILD=1 when building CLI binary
  @burrito_build System.get_env("BURRITO_BUILD") == "1"

  if @burrito_build do
    @impl true
    def start(_type, _args) do
      children = [
        {Task,
         fn ->
           Burrito.Util.Args.argv()
           |> DocSpec.CLI.main()
         end}
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: DocSpec.Supervisor)
    end
  else
    @impl true
    def start(_type, _args) do
      Supervisor.start_link([], strategy: :one_for_one, name: DocSpec.Supervisor)
    end
  end
end
