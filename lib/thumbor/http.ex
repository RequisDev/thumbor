defmodule Thumbor.HTTP do
  def get(adapter, uri, headers, options \\ []) do
    adapter.get(uri, headers, options)
  end

  def put(adapter, url, headers, body, options) do
    adapter.put(url, headers, body, options)
  end
end
