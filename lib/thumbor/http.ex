defmodule Thumbor.HTTP do
  def get(adapter, uri, options \\ []) do
    adapter.get(uri, options)
  end

  def put(adapter, url, body, options) do
    adapter.put(url, body, options)
  end
end
