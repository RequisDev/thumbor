defmodule Thumbor do
  @moduledoc """
  Documentation for `Thumbor`.
  """

  alias Thumbor.{
    Config,
    HTTP,
    Storage,
    CommonParams
  }

  @default_path "thumbor-results"

  @default_options []

  def build_url(image_url, params) do
    result_path = if Config.result_path(), do: Config.result_path(), else: @default_path

    [result_path, image_url]
    |> Path.join()
    |> CommonParams.convert_params_to_filter(params)
  end

  def build_request(host, security_code, url) do
    host
    |> URI.parse()
    |> Map.put(:path, "/#{security_code(security_code)}/#{url}")
    |> URI.to_string()
  end

  def request(http_adapter, host, security_code, url, options) do
    url = build_request(host, security_code, url)

    HTTP.get(http_adapter, url, [], options)
  end

  def find_result(
    bucket,
    storage_adapter,
    image_url,
    params,
    options
  ) do
    options = Keyword.merge(@default_options, options)

    url = build_url(image_url, params)

    Storage.head_object(storage_adapter, bucket, url, options)
  end

  def create_result(
    bucket,
    storage_adapter,
    http_adapter,
    host,
    security_code,
    image_url,
    params,
    options
  ) do
    options = Keyword.merge(@default_options, options)

    url = build_url(image_url, params)

    with {:ok, data} <- request(http_adapter, host, security_code, url, options),
      {:ok, presigned_upload} <- Storage.presigned_upload(storage_adapter, bucket, url, options),
      {:ok, metadata} <- HTTP.put(http_adapter, presigned_upload.url, data, [], options) do
      {:ok, %{
        destination_object: url,
        presigned_upload: presigned_upload,
        metadata: metadata
      }}
    end
  end

  def put_result(
    bucket,
    storage_adapter,
    http_adapter,
    host,
    security_code,
    image_url,
    params,
    destination_object,
    options
  ) do
    options = Keyword.merge(@default_options, options)

    url = build_url(image_url, params)

    with {:ok, data} <- request(http_adapter, host, security_code, url, options),
      {:ok, presigned_upload} <-
        Storage.presigned_upload(storage_adapter, bucket, destination_object, options) do
      HTTP.put(http_adapter, presigned_upload.url, data, [], options)
    end
  end

  defp security_code(nil), do: "unsafe"
  defp security_code(code), do: code
end
