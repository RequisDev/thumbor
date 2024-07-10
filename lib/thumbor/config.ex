defmodule Thumbor.Config do
  @app :thumbor

  def host do
    Application.get_env(@app, :host) || "localhost"
  end

  def http_adapter do
    Application.get_env(@app, :http_adapter)
  end

  def storage_adapter do
    Application.get_env(@app, :storage_adapter)
  end

  def security_code do
    Application.get_env(@app, :security_code)
  end

  def result_path do
    Application.get_env(@app, :result_path) || "thumbor-results"
  end
end
