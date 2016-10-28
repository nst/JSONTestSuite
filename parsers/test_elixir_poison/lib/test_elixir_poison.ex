defmodule TestElixirPoison do
  def main( _args = [file] ) do
    { :ok, json } = File.read( file )
    IO.inspect Poison.decode( json )
    case Poison.decode( json ) do
      { :ok, nil } -> exit({:shutdown, 1})
      { :ok, _ }   -> exit({:shutdown, 0})
      _            -> exit({:shutdown, 1})
    end
  end
end
