# frozen_string_literal: true

require "minitest/autorun"

require "typesmith"

class BasePropertyTest < Minitest::Test
  def setup
    @base_property = Typesmith::BaseProperty.new("test_property")
    @optional_property = Typesmith::BaseProperty.new("optional_property", optional: true)
  end

  def test_initialization
    assert_equal "test_property", @base_property.name
    refute @base_property.optional
    assert @optional_property.optional
  end

  def test_to_typescript_raises_not_implemented_error
    assert_raises(NotImplementedError) do
      @base_property.to_typescript
    end
  end

  def test_process_value_returns_original_value
    value = "test value"
    assert_equal value, @base_property.process_value(value)
  end

  def test_optional_suffix
    assert_equal "", @base_property.send(:optional_suffix)
    assert_equal "?", @optional_property.send(:optional_suffix)
  end

  def test_camelized_name
    assert_equal "testProperty", @base_property.send(:camelized_name)
    assert_equal "optionalProperty", @optional_property.send(:camelized_name)
  end

  def test_get_type_string
    assert_equal "string", @base_property.send(:get_type_string, :string)
    assert_equal "number", @base_property.send(:get_type_string, :number)
    assert_equal "boolean", @base_property.send(:get_type_string, :boolean)
    assert_equal "any", @base_property.send(:get_type_string, :any)
    assert_equal "null", @base_property.send(:get_type_string, :null)
    assert_equal "undefined", @base_property.send(:get_type_string, :undefined)
    assert_equal "void", @base_property.send(:get_type_string, :void)
    assert_equal "never", @base_property.send(:get_type_string, :never)
    assert_equal "unknown", @base_property.send(:get_type_string, :unknown)
    assert_equal "object", @base_property.send(:get_type_string, :object)
    assert_equal "Date", @base_property.send(:get_type_string, :Date)
  end

  def test_get_type_string_with_array
    assert_equal "string[]", @base_property.send(:get_type_string, [:string])
    assert_equal "number[]", @base_property.send(:get_type_string, [:number])
  end

  def test_get_type_string_with_hash
    assert_equal "{ [key: string]: number }", @base_property.send(:get_type_string, { string: :number })
    assert_equal "{ [key: number]: string }", @base_property.send(:get_type_string, { number: :string })
  end

  def test_get_type_string_with_custom_class
    custom_class = Class.new(Typesmith::Definition)
    custom_class.define_singleton_method(:typescript_type_name) { "CustomType" }
    assert_equal "CustomType", @base_property.send(:get_type_string, custom_class)
  end

  def test_validate_type
    Typesmith::BaseProperty::PRIMITIVE_TYPES.each do |type|
      assert_nil Typesmith::BaseProperty.validate_type(type)
    end

    custom_class = Class.new(Typesmith::Definition)
    assert_nil Typesmith::BaseProperty.validate_type(custom_class)

    assert_nil Typesmith::BaseProperty.validate_type([:string])
    assert_nil Typesmith::BaseProperty.validate_type({ string: :number })

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) do
      Typesmith::BaseProperty.validate_type(:invalid_type)
    end
  end
end
