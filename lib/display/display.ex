defmodule Display do
  use Bitwise

  @width 128
  @height 64
  @buffer_size round(@width * @height / 8)
  @bg_color 0
  
  def get_label(text, rows \\ 1, center \\ false) do
    text = text |> to_charlist
    # One row is 8 pixels
    img = :egd.create(@width, 8*rows)
    #Anyone knows any other fonts that work here? btw. it shrinks with canvas size, but it's never larger than 11px
    path = :filename.join([:code.priv_dir(:percept), "fonts", "6x11_latin1.wingsfont"])
    font = :egd_font.load(path)
    color = :egd.color(:black) #whatever

    x = 
      if center do
        {w,h} = :egd_font.size(font)
        len = length(text)
        round((@width/2 - w*len)/2)
      else 0 end    
    # there was nonzero default offset, -4 did the trick
    # but christ, it was a fight
    :egd.text(img, {x,-4}, font, text, color)    
    bitmap = :egd.render(img, :raw_bitmap)
    
    bitmap      
      |> :binary.bin_to_list
      |> monochrome
      |> convert_row
      |> pack_to_8bit
  end

  @doc """
    Light the whole screen
  """
  def all_on do
    1..@buffer_size
      |> Enum.map(fn (x) -> 255 end)
      |> display      
  end

  @doc """
    Draw a headline. Always centered and on the top.
    Takes 2 lines.
  """
  def draw_headline(text) do
    get_label(text, 2, true) |> display
  end

  @doc """
    Draw a string at a selected line. The text is being truncated.
    Max string length is @width / 6. So ~21 characters for 128px wide screen
  """
  def draw_string(text, line) do
    header_offset = 128*2
    get_label(text) ++ get_empty(header_offset + 128*line) |> display
  end
  
  @doc """
    Get any number of empty pixels to fill the bitmap.
  """
  def get_empty(0), do: []
  def get_empty(size) do
    1..size |> Enum.map (fn (_) -> @bg_color end)
  end

  @doc """
    Complements the bitmap to 1024 bytes
  """
  def complement(bitmap) when is_list(bitmap) do
    get_empty(@buffer_size - Enum.count(bitmap)) ++ bitmap
  end

  @doc """
    Send a ready frame to the device.
    Should be of length width * height / 8 - because we squeeze 8 pixels on one byte
  """
  def display(frame) when is_list(frame) do
    frame
      |> complement
      |> :binary.list_to_bin            
      |> SSD1306.Device.display
  end
  
  @doc """
    Convert a normal bitmap of size 128x8 to OLED compatible bitmap.
    OLEDs start counting from left-bottom corner and go up to 8, then move right..
  """
  def convert_row(bitmap) when is_list(bitmap) do
    bitmap
      |> Enum.chunk(@width)
      |> transpose
      |> List.flatten      
  end

  @doc """
  Transforsms RBG bitmap to a monochrome one.
  Resulting in 3 times shorter list.
  Whatever was black is black, other color will be highlighted.
  """
  def monochrome(rgb_bitmap) when is_list(rgb_bitmap) do
    rgb_bitmap 
      |> Enum.chunk(3)
      |> Enum.map(fn([r,g,b]) -> if r + g + b > 0 do @bg_color else 1 - @bg_color end end)
  end

  @doc """
    This function write 8 continous bytes into a sigle byte.
    The bitmap is expect to be monochome.
    Resulting list is 8 times shorter.
  """
  def pack_to_8bit(bitmap) when is_list(bitmap) do    
    bitmap      
      |> Enum.chunk(8)            
      |> Enum.map(fn(bits) -> elem(Enum.reduce(bits, {7,0}, fn (x, {i, acc}) -> {i-1, acc ||| x <<< i} end), 1) end)     
  end

  @doc """
    Transpose matrix (aka switch columns with rows)
  """
  def transpose([[]|_]), do: []
  def transpose(a) do
    [Enum.map(a, &hd/1) | transpose(Enum.map(a, &tl/1))]
  end

end
