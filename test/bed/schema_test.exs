defmodule Bed.SchemaTest do
  use ExUnit.Case

  @moduletag with_schema: TestSchema

  setup context do
    case Map.fetch(context, :with_schema) do
      {:ok, schema} -> %{schema: Bed.Schema.parse(schema)}
      _ -> %{}
    end
  end

  describe "parse/1" do
    test "returns basic info about the schema", %{schema: schema} do
      assert %{
               query_type: "RootQueryType",
               mutation_type: "RootMutationType",
               subscription_type: nil
             } = Map.take(schema, [:query_type, :mutation_type, :subscription_type])
    end

    test "we can get the type of a scalar", %{schema: schema} do
      assert %{kind: :scalar, name: "MyScalar", description: "A Scalar"} =
               find_by_name(schema.types, "MyScalar")
    end

    test "we can get the type of a object", %{schema: schema} do
      assert %{
               kind: :object,
               name: "TestObject",
               description: "An Object"
             } = object = find_by_name(schema.types, "TestObject")

      # Simple field with description
      assert %{
               name: "str",
               description: "A String",
               arguments: [],
               type: "String",
               deprecated?: false,
               deprecation_reason: nil
             } = find_by_name(object.fields, "str")

      # Complex field with complex type and arguments
      search_field = find_by_name(object.fields, "search")

      assert %{type: {:list, {:non_null, "String"}}} = search_field

      # Simple argument
      assert %{
               name: "offset",
               description: "Number of strings to skip",
               type: "Int",
               default_value: "0"
             } = find_by_name(search_field.arguments, "offset")

      # Complex argument type
      assert %{type: {:list, {:non_null, "String"}}} =
               find_by_name(search_field.arguments, "tags")

      # Deprecated field
      assert %{
               deprecated?: true,
               deprecation_reason: "Why not"
             } = find_by_name(object.fields, "deprecated")

      # Implemented interfaces
      assert ["WithStr", "WithTwoStrs"] == object.interfaces
    end

    test "we can get the type of an interface", %{schema: schema} do
      assert %{
               kind: :interface,
               name: "WithStr",
               description: "Contains a str field",
               fields: [
                 %{
                   name: "str",
                   description: nil,
                   arguments: [],
                   type: "String",
                   deprecated?: false,
                   deprecation_reason: nil
                 }
               ],
               possible_types: ["TestObject"],
               interfaces: []
             } = find_by_name(schema.types, "WithStr")
    end

    test "an interface can implement another interface", %{schema: schema} do
      assert %{
               kind: :interface,
               name: "WithTwoStrs",
               possible_types: ["TestObject"],
               interfaces: ["WithStr"]
             } = find_by_name(schema.types, "WithTwoStrs")
    end

    test "we can get the type of a union", %{schema: schema} do
      assert %{
               kind: :union,
               name: "MyScalarOrString",
               description: "My Scalar or a String",
               possible_types: ["MyScalar", "String"]
             } = find_by_name(schema.types, "MyScalarOrString")
    end

    test "we can get the type of an enum", %{schema: schema} do
      assert %{
               kind: :enum,
               name: "MyEnum",
               description: "An Enum",
               enum_values: enum_values
             } = find_by_name(schema.types, "MyEnum")

      assert %{
               name: "SIMPLE",
               description: nil,
               deprecated?: false,
               deprecation_reason: nil
             } = find_by_name(enum_values, "SIMPLE")

      assert %{description: "With Description"} = find_by_name(enum_values, "WITH_DESC")

      assert %{
               deprecated?: true,
               deprecation_reason: "Is no more"
             } = find_by_name(enum_values, "DEPRECATED")
    end

    test "we can get a input object type", %{schema: schema} do
      assert %{
               kind: :input_object,
               name: "MyInput",
               description: "An Input",
               input_fields: [
                 %{
                   name: "tags",
                   description: "A list of tags",
                   type: {:non_null, {:list, {:non_null, "String"}}},
                   default_value: "[]"
                 }
               ]
             } = find_by_name(schema.types, "MyInput")
    end

    test "we can parse GitHub Schema" do
      json = File.read!(Path.join(__DIR__, "./github_introspection_result.json"))
      {:ok, %{"data" => data}} = Jason.decode(json)

      assert %{query_type: "Query", mutation_type: "Mutation", types: types} =
               Bed.Schema.parse(data)

      # Some simple assertions
      assert %{name: "Query", fields: fields} = find_by_name(types, "Query")

      assert %{type: {:list, "CodeOfConduct"}} = find_by_name(fields, "codesOfConduct")
    end
  end

  defp find_by_name(list, name), do: Enum.find(list, &(&1.name == name))
end
