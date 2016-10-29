defmodule TestElixirJson do
  def main( _args = [file] ) do
    IO.inspect file
    { :ok, json } = File.read( file )
    IO.inspect json
    IO.inspect JSON.decode( json )
    case JSON.decode( json ) do
      { :ok, nil } -> exit({:shutdown, 1})
      { :ok, _ }   -> exit({:shutdown, 0})
      _            -> exit({:shutdown, 1})
    end
  end
end
