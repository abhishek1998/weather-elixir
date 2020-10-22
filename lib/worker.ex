defmodule Metex.Worker do
  def temperature_of(location) do
    result =
      url_for(location)
      |> HTTPoison.get()
      |> parse_response

    case result do
      {:ok, temp} ->
        "#{location} #{temp} deg C"

      :error ->
        "#{location} not found"
    end
  end

  def url_for(location) do
    location = URI.encode(location)

    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=6419a07329c82afa4092ffdd4eaf0c8e"
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!()
    |> compute_temperature
  end

  def compute_temperature(json) do
    try do
      temp =
        (json["main"]["temp"] - 273.15)
        |> Float.round(1)

      {:ok, temp}
    rescue
      _ -> :error
    end
  end
end

defmodule Metex.OTPWorker do
  use GenServer

  # [] is default value
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def temperature_of(location) do
    result =
      url_for(location)
      |> HTTPoison.get()
      |> parse_response

    case result do
      {:ok, temp} ->
        "#{location} #{temp} deg C"

      :error ->
        "#{location} not found"
    end
  end

  def get_temp(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  def handle_call({:location, location},_from,stats) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{temp} deg C", new_stats}

      _ ->
        {:reply, :error, stats}
    end
  end

  def url_for(location) do
    location = URI.encode(location)

    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=6419a07329c82afa4092ffdd4eaf0c8e"
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!()
    |> compute_temperature
  end

  def compute_temperature(json) do
    try do
      temp =
        (json["main"]["temp"] - 273.15)
        |> Float.round(1)

      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp update_stats(old_stat, location) do
    case Map.has_key?(old_stat, location) do
      true ->
        Map.update!(old_stat, location, &(&1 + 1))

      false ->
        Map.put_new(old_stat, location, 1)
    end
  end
end
