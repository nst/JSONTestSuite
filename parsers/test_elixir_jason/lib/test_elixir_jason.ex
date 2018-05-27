defmodule TestElixirJason do
  def main([file]) do
    input = File.read!(file)

    {result, details} =
      try do
        case input |> IO.inspect() |> Jason.decode() |> IO.inspect() do
          {:ok, result} -> {:accept, result}
          {:error, error} -> {:reject, error}
        end
      rescue
        e ->
          {:crash, e}
      end

    IO.puts(result)
    IO.inspect(details)

    exit({:shutdown, exit_status(result)})
  end

  defp exit_status(:accept), do: 0
  defp exit_status(:reject), do: 1
  defp exit_status(:crash), do: 2
end
