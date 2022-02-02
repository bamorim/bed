defmodule Bed.SchemaTest do
  use ExUnit.Case

  test "we can get the type of a scalar" do
    assert %{kind: :scalar, name: "NoDescScalar", description: nil} =
             Bed.Schema.named_type(TestSchema, "NoDescScalar")
  end

  test "we can get a scalar with description" do
    assert %{kind: :scalar, name: "DescScalar", description: "A Scalar"} =
             Bed.Schema.named_type(TestSchema, "DescScalar")
  end

  test "we can get the type of a object" do
    assert %{kind: :object, name: "NoDescObject", description: nil} =
             Bed.Schema.named_type(TestSchema, "NoDescObject")
  end

  test "we can get a object with description" do
    assert %{kind: :object, name: "DescObject", description: "An Object"} =
             Bed.Schema.named_type(TestSchema, "DescObject")
  end

  test "return nil for non-defined types" do
    assert is_nil(Bed.Schema.named_type(TestSchema, "InvalidType"))
  end
end
