defmodule Thumbor.Storage do

  @default_options []

  def head_object(adapter, object, options) do
    options = Keyword.merge(@default_options, options)

    adapter.head_object(object, options)
  end

  def presigned_upload(adapter, bucket, object, options \\ []) do
    options = Keyword.merge(@default_options, options)

    http_method = upload_http_method(options, :presigned_upload)

    presigned_url(adapter, bucket, http_method, object, options)
  end

  def presigned_url(adapter, bucket, http_method, object, options) do
    options = Keyword.merge(@default_options, options)

    bucket
    |> adapter.presigned_url(http_method, object, options)
    |> ensure_status_tuple!()
    |> handle_presigned_url_response()
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
end
