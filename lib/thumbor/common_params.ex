defmodule Thumbor.CommonParams do
  @moduledoc """
  See docs https://thumbor.readthedocs.io/en/latest/usage.html
  """

  @ordered_query_params [
    :metadata,
    :trim,
    :fit_in,
    :size,
    :h_align,
    :v_align,
    :smart,
    :filters
  ]

  @doc """
  Returns a thumbor uri string

  ### Examples

      Thumbor.CommonParams.convert_params_to_filter("example.jpg", %{
        metadata: true,
        smart: true,
        trim: %{left: 1, top: 2, right: 3, bottom: 4},
        fit_in: :full,
        size: %{width: 300, height: 300},
        h_align: 10,
        v_align: 10,
        filters: [
          brightness: %{amount: 10},
          contrast: %{amount: 10}
        ]
      })
      "metadata/trim/1x2:3x4/full-fit-in/300x300/10/10/smart/filters:brightness(10):contrast(10)/example.jpg"
  """
  @spec convert_params_to_filter(String.t(), map()) :: String.t()
  def convert_params_to_filter(image_uri, params \\ %{}) do
    @ordered_query_params
    |> Enum.reduce([], fn field, acc ->
      case Map.get(params, field) do
        nil -> acc
        value -> [convert_to_image_uri({field, value}) | acc]
      end
    end)
    |> Enum.reverse()
    |> Kernel.++([image_uri])
    |> Enum.join("/")
  end

  defp convert_to_image_uri({:fit_in, :default}) do
    "fit-in"
  end

  defp convert_to_image_uri({:fit_in, :full}) do
    "full-fit-in"
  end

  defp convert_to_image_uri({:fit_in, :adaptive}) do
    "adaptive-fit-in"
  end

  defp convert_to_image_uri({:h_align, value}) do
    "#{value}"
  end

  defp convert_to_image_uri({:v_align, value}) do
    "#{value}"
  end

  defp convert_to_image_uri({:metadata, true}) do
    "metadata"
  end

  defp convert_to_image_uri({:size, attrs}) do
    "#{attrs.width}x#{attrs.height}"
  end

  defp convert_to_image_uri({:smart, true}) do
    "smart"
  end

  defp convert_to_image_uri({:trim, attrs}) do
    "trim/#{attrs.left}x#{attrs.top}:#{attrs.right}x#{attrs.bottom}"
  end

  defp convert_to_image_uri({:filters, attrs}) do
    "filters:" <> Enum.map_join(attrs, ":", &convert_filters_to_image_uri/1)
  end

  defp convert_filters_to_image_uri({:brightness, attrs}) do
    "brightness(#{attrs.amount})"
  end

  defp convert_filters_to_image_uri({:contrast, attrs}) do
    "contrast(#{attrs.amount})"
  end
end
