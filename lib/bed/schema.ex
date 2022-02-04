defmodule Bed.Schema do
  @moduledoc """
  Introspect helpers on an absinth schema with simpler Elixir types.
  """

  @typedoc """
  A GraphQL Schema.

  It is based on the results of an introspection schema and should contain
  almost all the same information, but in a way that makes it easier to work
  with in Elixir.
  """
  @type t() :: %{
          types: [gql_named_type()],
          query_type: String.t(),
          mutation_type: String.t(),
          subscription_type: String.t()
        }

  @typedoc "A module defining an absinth schema"
  @type input_schema() :: Absinthe.Schema.t()

  # GraphQL Type Refs
  @type gql_type_ref() :: String.t() | {:list, gql_type_ref()} | {:non_null, gql_type_ref()}

  # Helper types
  @type gql_input_value() :: %{
          name: String.t(),
          description: String.t() | nil,
          type: gql_type_ref(),
          default_value: String.t() | nil
        }

  @type gql_field() :: %{
          name: String.t(),
          description: String.t() | nil,
          arguments: [gql_input_value()],
          type: gql_type_ref(),
          deprecated?: boolean(),
          deprecation_reason: String.t() | nil
        }

  @type gql_enum_value() :: %{
          name: String.t(),
          description: String.t() | nil,
          deprecated?: boolean(),
          deprecation_reason: String.t() | nil
        }

  # GraphQL Types Types
  @type gql_scalar() :: %{
          kind: :scalar,
          name: String.t(),
          description: String.t() | nil
        }
  @type gql_object() :: %{
          kind: :object,
          name: String.t(),
          description: String.t() | nil,
          fields: [gql_field()],
          interfaces: [String.t()]
        }
  @type gql_interface() :: %{
          kind: :interface,
          name: String.t(),
          description: String.t(),
          fields: [gql_field()],
          interfaces: [String.t()],
          possible_types: [String.t()]
        }
  @type gql_union() :: %{
          kind: :input_object,
          name: String.t(),
          description: String.t() | nil,
          possible_types: [String.t()]
        }
  @type gql_enum() :: %{
          kind: :enum,
          name: String.t(),
          description: String.t() | nil,
          enum_values: [gql_enum_value()]
        }
  @type gql_input_object() :: %{
          kind: :input_object,
          name: String.t(),
          description: String.t() | nil,
          input_fields: [gql_input_value()]
        }

  @typedoc "GQL Types that have a name"
  @type gql_named_type() ::
          gql_scalar()
          | gql_object()
          | gql_interface()
          | gql_union()
          | gql_enum()
          | gql_input_object()

  @spec parse(module() | map()) :: t()
  def parse(schema) when is_atom(schema) do
    {:ok, %{data: data}} = Absinthe.Schema.introspect(schema)

    parse(data)
  end

  def parse(%{"__schema" => schema}) do
    %{
      types: Enum.map(schema["types"] || [], &parse_type/1),
      query_type: schema["queryType"]["name"],
      mutation_type: schema["mutationType"]["name"],
      subscription_type: schema["subscriptionType"]["name"]
    }
  end

  defp parse_type(%{"kind" => "SCALAR"} = type), do: parse_scalar(type)
  defp parse_type(%{"kind" => "OBJECT"} = type), do: parse_object(type)
  defp parse_type(%{"kind" => "INTERFACE"} = type), do: parse_interface(type)
  defp parse_type(%{"kind" => "UNION"} = type), do: parse_union(type)
  defp parse_type(%{"kind" => "ENUM"} = type), do: parse_enum(type)
  defp parse_type(%{"kind" => "INPUT_OBJECT"} = type), do: parse_input_object(type)

  @spec parse_scalar(map()) :: gql_scalar()
  def parse_scalar(type) do
    %{kind: :scalar, name: type["name"], description: type["description"]}
  end

  @spec parse_object(map()) :: gql_object()
  def parse_object(type) do
    %{
      kind: :object,
      name: type["name"],
      description: type["description"],
      fields: Enum.map(type["fields"] || [], &parse_field/1),
      interfaces: Enum.map(type["interfaces"] || [], & &1["name"])
    }
  end

  @spec parse_interface(map()) :: gql_interface()
  def parse_interface(type) do
    %{
      kind: :interface,
      name: type["name"],
      description: type["description"],
      fields: Enum.map(type["fields"] || [], &parse_field/1),
      possible_types: Enum.map(type["possibleTypes"] || [], & &1["name"]),
      interfaces: Enum.map(type["interfaces"] || [], & &1["name"])
    }
  end

  @spec parse_union(map()) :: gql_union()
  def parse_union(type) do
    %{
      kind: :union,
      name: type["name"],
      description: type["description"],
      possible_types: Enum.map(type["possibleTypes"] || [], & &1["name"])
    }
  end

  @spec parse_enum(map()) :: gql_enum()
  def parse_enum(type) do
    %{
      kind: :enum,
      name: type["name"],
      description: type["description"],
      enum_values: Enum.map(type["enumValues"] || [], &parse_enum_value/1)
    }
  end

  @spec parse_input_object(map()) :: gql_input_object()
  def parse_input_object(type) do
    %{
      kind: :input_object,
      name: type["name"],
      description: type["description"],
      input_fields: Enum.map(type["inputFields"] || [], &parse_input_value/1)
    }
  end

  @spec parse_field(map()) :: gql_field()
  def parse_field(field) do
    %{
      name: field["name"],
      description: field["description"],
      arguments: Enum.map(field["args"] || [], &parse_input_value/1),
      type: parse_type_ref(field["type"]),
      deprecated?: field["isDeprecated"],
      deprecation_reason: field["deprecationReason"]
    }
  end

  @spec parse_input_value(map()) :: gql_input_value()
  def parse_input_value(input) do
    %{
      name: input["name"],
      description: input["description"],
      type: parse_type_ref(input["type"]),
      default_value: input["defaultValue"]
    }
  end

  @spec parse_enum_value(map()) :: gql_enum_value()
  def parse_enum_value(eval) do
    %{
      name: eval["name"],
      description: eval["description"],
      deprecated?: eval["isDeprecated"],
      deprecation_reason: eval["deprecationReason"]
    }
  end

  @spec parse_type_ref(map()) :: gql_type_ref()
  def parse_type_ref(%{"kind" => "LIST", "ofType" => inner}) do
    {:list, parse_type_ref(inner)}
  end

  def parse_type_ref(%{"kind" => "NON_NULL", "ofType" => inner}) do
    {:non_null, parse_type_ref(inner)}
  end

  def parse_type_ref(%{"name" => name}), do: name
end
