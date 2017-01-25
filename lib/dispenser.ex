defmodule Dispenser do
  require EEx

  defmodule Request do
    defstruct  uri: nil, method: nil , namespace: nil, header_params: nil, params: []
    @type t :: %__MODULE__{uri: String.t, method: String.t, namespace: String.t, header_params: list(list), params: list(list)}
  end

  defmodule Item do
    defstruct name: nil, value: nil, attributes: []
    @type t :: %__MODULE__{name: String.t, value: list(list), attributes: list(list)}
  end

  EEx.function_from_file(:def, :generate_xml, Path.expand("./templates/template.xml.eex"), [:soap_request])
  EEx.function_from_file(:def, :generate_item_without_attr, Path.expand("./templates/values.xml.eex"), [:values])
  EEx.function_from_file(:def, :generate_item_with_attr, Path.expand("./templates/values_with_attrs.xml.eex"), [:item])

  def generate_item(%Dispenser.Item{} = item), do: generate_item_with_attr(item)
  def generate_item(item), do: generate_item_without_attr(item)

  def get_value(%Dispenser.Item{} = value), do: generate_item(value)
  def get_value(value) when Kernel.is_list(value), do: generate_item_without_attr(value)
  def get_value(value), do: value

  def do_request(%Dispenser.Request{} = request) do
      request_header = get_headers(request)
      request_body = generate_xml(request)
      res = HTTPoison.post!(request.uri, request_body, request_header, [recv_timeout: 10000])
      case(res) do
        %HTTPoison.Response{status_code: 200, body: res_body} ->
          {:ok, res_body}
      end
  end

  defp get_headers(%Dispenser.Request{} = request) do
    [{"Content-Type", "text/xml"}, {"SOAPACTION", "urn:#{request.namespace}##{request.method}"}]
  end
end