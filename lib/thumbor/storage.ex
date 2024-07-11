defmodule Thumbor.Storage do

  @default_options []

  def head_object(adapter, bucket, object, options) do
    options = Keyword.merge(@default_options, options)

    sandbox? = options[:storage][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_head_object_response(bucket, object, options)
    else
      bucket
      |> adapter.head_object(object, options)
      |> ensure_status_tuple!()
    end
  end

  def presigned_upload(adapter, bucket, object, options \\ []) do
    options = Keyword.merge(@default_options, options)

    http_method = upload_http_method(options, :presigned_upload)

    presigned_url(adapter, bucket, http_method, object, options)
  end

  def presigned_url(adapter, bucket, http_method, object, options) do
    options = Keyword.merge(@default_options, options)

    sandbox? = options[:storage][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_presigned_url_response(bucket, http_method, object, options)
    else
      bucket
      |> adapter.presigned_url(http_method, object, options)
      |> ensure_status_tuple!()
      |> handle_presigned_url_response()
    end
  end

  defp upload_http_method(options, action) do
    case options[:storage][action][:http_method] do
      :post -> :post
      :put -> :put
      term -> raise ArgumentError, "expected `:put` or `:put`, got: #{inspect(term)}"
    end
  end

  defp handle_presigned_url_response({:ok, %{url: url, expires_at: expires_at}} = ok)
    when is_binary(url) and
    is_struct(expires_at, DateTime) do
    ok
  end

  defp handle_presigned_url_response({:ok, term}) do
    raise """
    Expected one of:

    {:ok, %{url: String.t(), expires_at: DateTime.t()}}
    {:error, term()}

    got:

    #{inspect(term, pretty: true)}
    """
  end

  defp handle_presigned_url_response(response) do
    response
  end

  defp ensure_status_tuple!({:ok, _} = ok), do: ok
  defp ensure_status_tuple!({:error, _} = error), do: error

  defp ensure_status_tuple!(term) do
    raise """
    Expected one of:

    {:ok, term()}
    {:error, term()}

    got:

    #{inspect(term, pretty: true)}
    """
  end

  if Mix.env() === :test do
    defdelegate sandbox_head_object_response(bucket, object, options),
      to: Thumbor.Support.StorageSandbox,
      as: :head_object_response

    defdelegate sandbox_presigned_url_response(bucket, method, object, options),
      to: Thumbor.Support.StorageSandbox,
      as: :presigned_url_response

    defdelegate sandbox_disabled?, to: Thumbor.Support.StorageSandbox
  else
    defp sandbox_head_object_response(bucket, object, options) do
      raise """
      Cannot use StorageSandbox outside of test

      bucket: #{inspect(bucket)}
      object: #{inspect(object)}
      options: #{inspect(options, pretty: true)}
      """
    end

    defp sandbox_presigned_url_response(bucket, method, object, options) do
      raise """
      Cannot use StorageSandbox outside of test

      bucket: #{inspect(bucket)}
      method: #{inspect(method)}
      object: #{inspect(object)}
      options: #{inspect(options, pretty: true)}
      """
    end

    defp sandbox_disabled?, do: true
  end
end
