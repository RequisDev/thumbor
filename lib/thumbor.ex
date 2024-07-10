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

  def build_uri(image_uri, params) do
    result_path = if Config.result_path(), do: Config.result_path(), else: @default_path

    [result_path, image_uri]
    |> Path.join()
    |> CommonParams.convert_params_to_filter(params)
  end

  def build_request(host, security_code, uri) do
    host
    |> URI.parse()
    |> Map.put(:path, "/#{security_code(security_code)}/#{uri}")
    |> URI.to_string()
  end

  def request(http_adapter, host, security_code, uri, options \\ []) do
    uri = build_request(host, security_code, uri)

    HTTP.get(http_adapter, uri, options)
  end

  def find_result(storage_adapter, image_uri, params \\ %{}, options \\ []) do
    uri = build_uri(image_uri, params)

    Storage.head_object(storage_adapter, uri, options)
  end

  def create_result(
    http_adapter,
    host,
    security_code,
    storage_adapter,
    image_uri,
    params,
    options \\ []
  ) do
    uri = build_uri(image_uri, params)

    with {:ok, data} <- request(http_adapter, host, security_code, uri, options),
        {:ok, presigned_upload} <- Storage.presigned_upload(storage_adapter, uri, options),
        {:ok, metadata} <- HTTP.put(http_adapter, presigned_upload.url, data, options) do
      {:ok, %{
        destination_object: uri,
        presigned_upload: presigned_upload,
        metadata: metadata
      }}
    end
  end

  def put_result(
    http_adapter,
    host,
    security_code,
    image_uri,
    params \\ %{},
    storage_adapter,
    dest_object,
    options \\ []
  ) do
    uri = build_uri(image_uri, params)

    with {:ok, data} <- request(http_adapter, host, security_code, uri, options),
        {:ok, presigned_upload} <- Storage.presigned_upload(storage_adapter, dest_object, options) do
      HTTP.put(http_adapter, presigned_upload.url, data, options)
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

      @host host
      @http_adapter http_adapter
      @storage_adapter storage_adapter

      def host, do: @host
      def security_code, do: @security_code
      def http_adapter, do: @http_adapter
      def storage_adapter, do: @storage_adapter

      def build_uri(image_uri, params) do
        Thumbor.build_uri(image_uri, params)
      end

      def build_request(uri) do
        Thumbor.build_request(@host, @security_code, uri)
      end

      def request(uri, options \\ []) do
        Thumbor.request(
          @http_adapter,
          @host,
          @security_code,
          uri,
          options
        )
      end

      def find_result(image_uri, params \\ %{}, options \\ []) do
        Thumbor.find_result(
          @storage_adapter,
          image_uri,
          params,
          options
        )
      end

      def create_result(image_uri, params \\ %{}, options \\ []) do
        Thumbor.create_result(
          @http_adapter,
          @host,
          @security_code,
          @storage_adapter,
          image_uri,
          params,
          options\
        )
      end

      def put_result(image_uri, params \\ %{}, dest_object, options \\ []) do
        Thumbor.put_result(
          @http_adapter,
          @host,
          @security_code,
          image_uri,
          params,
          @storage_adapter,
          dest_object,
          options
        )
      end
    end
  end
end
