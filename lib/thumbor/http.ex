defmodule Thumbor.HTTP do
  def get(adapter, url, headers, options) do
    adapter.get(url, headers, options)
  end

  def put(adapter, url, body, headers, options) do
    adapter.put(url, body, headers, options)
  end
end
