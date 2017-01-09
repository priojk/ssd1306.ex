defmodule SSD1306 do
    @moduledoc """
        Module responsible for interfacing with a SSD1306 screen.
    """

    use Application
    alias SSD1306.{Display, Device}

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        args = Application.get_env(:SSD1306, :device, {bus: "i2c-1", address: 0x3c, reset_pin: 24, commands: []})

        children = [
            worker(SSD1306.Device, args)
            worker(SSD1306.Display, [])
        ]

        opts = [strategy: :one_for_one, name: SSD1306.Supervisor]
        Supervisor.start_link(children, opts)
    end

    defdelegate all_on, to: Device
    defdelegate all_off, to: Device
    defdelegate reset, to: Device
    defdelegate set_headline(text), to: Display
    defdelegate set_line(text, line), to: Display

end
