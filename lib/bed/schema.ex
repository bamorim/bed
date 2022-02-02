defmodule Bed.Schema do
  @moduledoc """
  Introspect helpers on an absinth schema with simpler Elixir types.
  """

  @typedoc "A module defining an absinth schema"
  @type input_schema() :: Absinthe.Schema.t()

  # GraphQL Type Refs
  @type gql_type_ref() :: String.t() | {:list_of, gql_type_ref()} | {:non_null, gql_type_ref()}

  # Helper types
  @type gql_input_value() :: %{
          name: String.t(),
          description: String.t() | nil,
          type: gql_type_ref(),
          default_value: String.t() | nil,
          deprecated?: boolean(),
          deprecation_reason: String.t() | nil
        }

  @type gql_field() :: %{
          name: String.t(),
          description: String.t() | nil,
          args: [gql_input_value()],
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

  @spec named_type(input_schema(), String.t()) :: gql_named_type() | nil
  def named_type(schema, name) do
    {:ok, %{data: %{"__schema" => %{"types" => types}}}} = Absinthe.Schema.introspect(schema)

    case Enum.find(types, &(&1["name"] == name)) do
      %{"kind" => "SCALAR"} = type -> parse_scalar(type)
      %{"kind" => "OBJECT"} = type -> parse_object(type)
      nil -> nil
    end
  end

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
      fields: [],
      interfaces: []
    }
  end
end
