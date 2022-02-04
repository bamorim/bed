defmodule TestSchema do
  use Absinthe.Schema

  @desc "A Scalar"
  scalar :my_scalar do
  end

  @desc "An Object"
  object :test_object do
    interface :with_str
    interface :with_two_strs

    @desc "A String"
    field :str, :string
    field :str2, :string

    field :search, list_of(non_null(:string)) do
      @desc "Number of strings to skip"
      arg :offset, :integer, default_value: 0
      arg :tags, list_of(non_null(:string))
    end

    field :deprecated, :string do
      deprecate "Why not"
    end
  end

  @desc "Contains a str field"
  interface :with_str do
    field :str, :string

    resolve_type fn _, _ -> :test_object end
  end

  interface :with_two_strs do
    interface :with_str
    field :str, :string
    field :str2, :string
    resolve_type fn _, _ -> :double_iface_object end
  end

  @desc "My Scalar or a String"
  union :my_scalar_or_string do
    types [:my_scalar, :string]
    resolve_type fn
      "x" <> _ -> :my_scalar
      _ -> :string
    end
  end

  @desc "An Enum"
  enum :my_enum do
    value :simple
    value :with_desc, description: "With Description"
    value :deprecated, deprecate: "Is no more"
  end

  @desc "An Input"
  input_object :my_input do
    @desc "A list of tags"
    field :tags, non_null(list_of(non_null(:string))), default_value: []
  end

  query do
    field :test_object, :test_object
    field :my_scalar, :my_scalar
    field :my_scalar_or_string, :my_scalar_or_string
    field :my_enum, :my_enum
  end

  mutation do
    field :create_tags, :boolean do
      arg :input, :my_input
    end
  end
end
