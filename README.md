# SSD1306

##Usage

Turn on the display:
```elixir
  SSD1306.Device.all_on
```
Turn off the display:
```elixir
  SSD1306.Device.all_off
```

Set headline (big centered yellow text)
```elixir
  SSD1306.Device.set_headline(text)
```

Set line of text (0-5)
```elixir
  SSD1306.Device.set_line(text, line)
```

![example](http://i.imgur.com/6WX7VxQ.jpg "Example")


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `ssd1306` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ssd1306, "~> 0.1.0"}]
    end
    ```

  2. Ensure `ssd1306` is started before your application:

    ```elixir
    def application do
      [applications: [:ssd1306]]
    end
    ```

