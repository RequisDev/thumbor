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

  def build_url(image_url, params) do
    result_path = if Config.result_path(), do: Config.result_path(), else: @default_path

    [result_path, image_url]
    |> Path.join()
    |> CommonParams.convert_params_to_filter(params)
  end

  def build_request(host, security_code, url) do
    host
    |> url.parse()
    |> Map.put(:path, "/#{security_code(security_code)}/#{url}")
    |> url.to_string()
  end

  def request(http_adapter, host, security_code, url, options) do
    url = build_request(host, security_code, url)

    HTTP.get(http_adapter, url, [], options)
  end

  def find_result(storage_adapter, bucket, image_url, params \\ %{}, options \\ []) do
    url = build_url(image_url, params)

    Storage.head_object(storage_adapter, bucket, url, options)
  end

  def create_result(
    http_adapter,
    host,
    security_code,
    storage_adapter,
    bucket,
    image_url,
    params,
    options \\ []
  ) do
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
    http_adapter,
    host,
    security_code,
    image_url,
    params \\ %{},
    storage_adapter,
    bucket,
    dest_object,
    options \\ []
  ) do
    url = build_url(image_url, params)

    with {:ok, data} <- request(http_adapter, host, security_code, url, options),
      {:ok, presigned_upload} <-
        Storage.presigned_upload(storage_adapter, bucket, dest_object, options) do
      HTTP.put(http_adapter, presigned_upload.url, data, [], options)
    end
  end

  defp security_code(nil), do: "unsafe"
  defp security_code(code), do: code

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)

      alias Thumbor.Config

      host = opts[:host] || Config.host()
      security_code = opts[:security_code] || Config.security_code()
      http_adapter = opts[:http_adapter] || Config.http_adapter()
      storage_adapter = opts[:storage_adapter] || Config.storage_adapter()
      bucket = opts[:bucket] || Config.bucket()

      @host host
      @http_adapter http_adapter
      @storage_adapter storage_adapter
      @bucket bucket

      def host, do: @host
      def security_code, do: @security_code
      def http_adapter, do: @http_adapter
      def storage_adapter, do: @storage_adapter
      def bucket, @bucket

      def build_url(image_url, params) do
        Thumbor.build_url(image_url, params)
      end

      def build_request(url) do
        Thumbor.build_request(@host, @security_code, url)
      end

      def request(url, options \\ []) do
        Thumbor.request(
          @http_adapter,
          @host,
          @security_code,
          url,
          options
        )
      end

      def find_result(image_url, params \\ %{}, options \\ []) do
        Thumbor.find_result(
          @storage_adapter,
          @bucket,
          image_url,
          params,
          options
        )
      end

      def create_result(image_url, params \\ %{}, options \\ []) do
        Thumbor.create_result(
          @http_adapter,
          @host,
          @security_code,
          @storage_adapter,
          @bucket,
          image_url,
          params,
          options\
        )
      end

      def put_result(image_url, params \\ %{}, dest_object, options \\ []) do
        Thumbor.put_result(
          @http_adapter,
          @host,
          @security_code,
          image_url,
          params,
          @storage_adapter,
          @bucket,
          dest_object,
          options
        )
      end
    end
  end
end
