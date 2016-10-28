defmodule TestElixirExjson do
  def main( _args = [file] ) do
    { :ok, json } = File.read( file )
    IO.inspect ExJSON.parse( json )
    case ExJSON.parse( json ) do
      { _, :exjson_to_keyword, _ } -> exit({:shutdown, 1})
      nil                          -> exit({:shutdown, 1})
      _                            -> exit({:shutdown, 0})
    end
  end
end
