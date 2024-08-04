# frozen_string_literal: true

require "minitest/autorun"
require "typesmith"

class SimplePropertyTest < Minitest::Test
  class CustomType < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
  end

  def setup
    @string_prop = Typesmith::SimpleProperty.new("name", :string)
    @number_prop = Typesmith::SimpleProperty.new("age", :number)
    @boolean_prop = Typesmith::SimpleProperty.new("is_active", :boolean)
    @optional_prop = Typesmith::SimpleProperty.new("email", :string, optional: true)
    @custom_prop = Typesmith::SimpleProperty.new("custom", CustomType)
    @array_prop = Typesmith::SimpleProperty.new("tags", [:string])
  end

  def test_initialization
    assert_equal "name", @string_prop.name
    assert_equal :string, @string_prop.type
    refute @string_prop.optional
    assert @optional_prop.optional
  end

  def test_to_typescript
    assert_equal "name: string;", @string_prop.to_typescript
    assert_equal "age: number;", @number_prop.to_typescript
    assert_equal "isActive: boolean;", @boolean_prop.to_typescript
    assert_equal "email?: string;", @optional_prop.to_typescript
    assert_equal "custom: CustomType;", @custom_prop.to_typescript
    assert_equal "tags: string[];", @array_prop.to_typescript
  end

  def test_process_value
    assert_equal "John", @string_prop.process_value("John")
    assert_equal 30, @number_prop.process_value(30)
    assert_equal true, @boolean_prop.process_value(true)
    assert_equal %w[tag1 tag2], @array_prop.process_value(%w[tag1 tag2])

    custom_value = { id: 1, name: "Test" }
    processed_custom = @custom_prop.process_value(custom_value)
    assert_equal custom_value, processed_custom
    assert_instance_of Hash, processed_custom
  end

  def test_validate_type
    assert_nil Typesmith::SimpleProperty.validate_type(:string)
    assert_nil Typesmith::SimpleProperty.validate_type(:number)
    assert_nil Typesmith::SimpleProperty.validate_type(:boolean)
    assert_nil Typesmith::SimpleProperty.validate_type([:string])
    assert_nil Typesmith::SimpleProperty.validate_type(CustomType)

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) do
      Typesmith::SimpleProperty.new("invalid", :invalid_type)
    end
  end

  def test_camelized_name
    assert_equal "name", @string_prop.send(:camelized_name)
    assert_equal "age", @number_prop.send(:camelized_name)
    assert_equal "isActive", @boolean_prop.send(:camelized_name)
  end

  def test_get_type_string
    assert_equal "string", @string_prop.send(:get_type_string, :string)
    assert_equal "number", @number_prop.send(:get_type_string, :number)
    assert_equal "boolean", @boolean_prop.send(:get_type_string, :boolean)
    assert_equal "CustomType", @custom_prop.send(:get_type_string, CustomType)
    assert_equal "string[]", @array_prop.send(:get_type_string, [:string])
  end
end
