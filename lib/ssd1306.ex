defmodule SSD1306 do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
        worker(SSD1306.Device, [%{bus: "i2c-1", address: 0x3c, reset_pin: 24}])
    ]
    opts = [strategy: :one_for_one, name: SSD1306.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
