defmodule TestSchema do
  use Absinthe.Schema

  @desc "A Scalar"
  scalar :desc_scalar do
  end

  scalar :no_desc_scalar do
  end

  @desc "An Object"
  object :desc_object do
    field :str, :string
  end

  object :no_desc_object do
    field :str, :string
  end

  query do
    field :str, :string
    field :desc_scalar, :desc_scalar
    field :no_desc_scalar, :no_desc_scalar
    field :desc_object, :desc_object
    field :no_desc_object, :no_desc_object
  end
end
