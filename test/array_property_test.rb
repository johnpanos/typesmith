# frozen_string_literal: true

require "minitest/autorun"
require "typesmith"

class ArrayPropertyTest < Minitest::Test
  class CustomType < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
  end

  def setup
    @string_array = Typesmith::ArrayProperty.new("tags", :string)
    @number_array = Typesmith::ArrayProperty.new("scores", :number)
    @boolean_array = Typesmith::ArrayProperty.new("flags", :boolean)
    @custom_array = Typesmith::ArrayProperty.new("items", CustomType)
    @optional_array = Typesmith::ArrayProperty.new("optional_tags", :string, optional: true)
    @nested_array = Typesmith::ArrayProperty.new("matrix", [:number])
  end

  def test_initialization
    assert_equal "tags", @string_array.name
    assert_equal :string, @string_array.type
    refute @string_array.optional
    assert @optional_array.optional
  end

  def test_to_typescript
    assert_equal "tags: string[];", @string_array.to_typescript
    assert_equal "scores: number[];", @number_array.to_typescript
    assert_equal "flags: boolean[];", @boolean_array.to_typescript
    assert_equal "items: CustomType[];", @custom_array.to_typescript
    assert_equal "optionalTags?: string[];", @optional_array.to_typescript
    assert_equal "matrix: number[][];", @nested_array.to_typescript
  end

  def test_process_value
    assert_equal %w[a b c], @string_array.process_value(%w[a b c])
    assert_equal [1, 2, 3], @number_array.process_value([1, 2, 3])
    assert_equal [true, false, true], @boolean_array.process_value([true, false, true])

    custom_values = [{ id: 1, name: "Item 1" }, { id: 2, name: "Item 2" }]
    processed_custom = @custom_array.process_value(custom_values)
    assert_equal custom_values, processed_custom
    assert_instance_of Array, processed_custom
    assert_instance_of Hash, processed_custom.first

    assert_equal [[1, 2], [3, 4]], @nested_array.process_value([[1, 2], [3, 4]])
  end

  def test_validate_type
    assert_nil Typesmith::ArrayProperty.validate_type(:string)
    assert_nil Typesmith::ArrayProperty.validate_type(:number)
    assert_nil Typesmith::ArrayProperty.validate_type(:boolean)
    assert_nil Typesmith::ArrayProperty.validate_type(CustomType)
    assert_nil Typesmith::ArrayProperty.validate_type([:number])

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) do
      Typesmith::ArrayProperty.new("invalid", :invalid_type)
    end
  end

  def test_camelized_name
    assert_equal "tags", @string_array.send(:camelized_name)
    assert_equal "scores", @number_array.send(:camelized_name)
    assert_equal "optionalTags", @optional_array.send(:camelized_name)
  end

  def test_get_type_string
    assert_equal "string", @string_array.send(:get_type_string, @string_array.type)
    assert_equal "number", @number_array.send(:get_type_string, @number_array.type)
    assert_equal "boolean", @boolean_array.send(:get_type_string, @boolean_array.type)
    assert_equal "CustomType", @custom_array.send(:get_type_string, @custom_array.type)
    assert_equal "number[]", @nested_array.send(:get_type_string, @nested_array.type)
  end
end
