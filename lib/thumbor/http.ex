defmodule Thumbor.HTTP do
  @default_options []

  def get(adapter, url, headers, options \\ []) do
    options = Keyword.merge(@default_options, options)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_get_response(url, headers, options)
    else
      adapter.get(url, headers, options)
    end
  end

  def put(adapter, url, body, headers, options) do
    options = Keyword.merge(@default_options, options)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_put_response(url, body, headers, options)
    else
      adapter.put(url, body, headers, options)
    end
  end

  if Mix.env() === :test do
    defdelegate sandbox_get_response(url, headers, options),
      to: Thumbor.Support.HTTPSandbox,
      as: :get_response

    defdelegate sandbox_put_response(url, body, headers, options),
      to: Thumbor.Support.HTTPSandbox,
      as: :put_response

    defdelegate sandbox_disabled?, to: Thumbor.Support.HTTPSandbox
  else
    defp sandbox_get_response(url, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_put_response(url, _, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_disabled?, do: true
  end
end
