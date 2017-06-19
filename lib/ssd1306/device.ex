defmodule SSD1306.Device do

  alias ElixirALE.I2C
  alias ElixirALE.GPIO
  
  alias SSD1306.{Device, Commands}
  use GenServer
  use Bitwise
  require Logger

  def start_link(%{bus: _, address: _, reset_pin: _}=config) do
    GenServer.start_link(__MODULE__, [config], name: __MODULE__)
  end

  def display(buffer) when is_binary(buffer), do: GenServer.call(__MODULE__, {:display, buffer})
  def all_on, do: GenServer.call(__MODULE__, :all_on)
  def all_off, do: GenServer.call(__MODULE__, :all_off)
  def reset, do: GenServer.call(__MODULE__, :reset)

  def init([%{bus: bus, address: address, reset_pin: reset}=state]) do
    # gproc_reg(bus, address)
    width  = Map.get(state, :width, 128)
    height = Map.get(state, :height, 64)

    Logger.info("Connecting to SSD1306 device #{device_name state} (#{width}x#{height})")
    {:ok, i2c}  = I2C.start_link(bus, address)
    {:ok, gpio} = GPIO.start_link(reset, :output)

    state = state
      |> Map.put(:width, width)
      |> Map.put(:height, height)
      |> Map.put(:i2c, i2c)
      |> Map.put(:reset, gpio)

    case reset_device(state) do
      :ok         -> {:ok, state}
      {:error, e} -> {:stop, e}
    end
    {:ok, state}
  end

  def handle_call(:all_on, from, state) do
    buffer = all_on_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call(:all_off, from, state) do
    buffer = all_off_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call(:reset, _from, state) do
    reset_device(state)
    {:reply, :ok, state}
  end

  def handle_call({:display, buffer}, _from, %{width: width, height: height}=state) do
    with :ok <- validate_buffer(buffer, width, height),
         :ok <- Commands.display(state, buffer)
         do
           {:reply, :ok, state}
         else
           err -> {:reply, err, state}
          end
  end

  defp validate_buffer(buffer, width, height) when byte_size(buffer) == width * height / 8, do: :ok
  defp validate_buffer(buffer, width, height), do: {:error, "Expected buffer of #{div(width * height, 8)} bytes but received buffer of #{byte_size(buffer)} bytes."}

  defp reset_device(%{i2c: i2c, reset: gpio}=state) do
    commands = Map.get(state, :commands, [])
    with :ok <- Commands.reset!(gpio),
         :ok <- Commands.initialize!(state),
         :ok <- Commands.display(state, all_off_buffer(state)),
         :ok <- apply_commands(i2c, commands),
         :ok <- Commands.display_on!(i2c),
         do: :ok
  end

  defp all_on_buffer(state),  do: initialize_buffer(state, 1)
  defp all_off_buffer(state), do: initialize_buffer(state, 0)

  def initialize_buffer(%{width: width, height: height}, value) when value == 0 or value == 1 do
    byte_len = div(width * height, 8)
    bytes    = 0..15 |> Enum.reduce(0, fn i, b -> (value <<< i) + b end)
    1..byte_len |> Enum.reduce(<<>>, fn _, buf -> buf <> <<bytes>> end)
  end

  defp apply_commands(pid, commands) do
    Enum.reduce(commands, :ok, fn
      _, {:error, _}=error
        -> error
      command, :ok when is_atom(command) ->
        apply(Commands, command, [pid])
      {command, args}, :ok when is_atom(command) and is_list(args) ->
        apply(Commands, command, [pid | args])
      {command, arg}, :ok when is_atom(command) ->
        apply(Commands, command, [pid, arg])
    end)
  end

  defp device_name(%{bus: bus, address: address, reset_pin: reset}), do: "#{bus}:#{i2h address}(#{reset})"
  defp i2h(i), do: "0x" <> Integer.to_string(i, 16)

end
