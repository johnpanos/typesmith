# frozen_string_literal: true

require "minitest/autorun"
require "typesmith"

class IndexedPropertyTest < Minitest::Test
  class CustomClass < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
  end

  def setup
    @simple_indexed = Typesmith::IndexedProperty.new("simple_scores", :string, :number)
    @optional_indexed = Typesmith::IndexedProperty.new("optional_scores", :string, :number, optional: true)
    @nested_indexed = Typesmith::IndexedProperty.new("nested_scores", :string, [:number])
    @complex_indexed = Typesmith::IndexedProperty.new("complex_scores", :string, CustomClass)
  end

  def test_initialization
    assert_equal "simple_scores", @simple_indexed.name
    assert_equal :string, @simple_indexed.key_type
    assert_equal :number, @simple_indexed.value_type
    refute @simple_indexed.optional
    assert @optional_indexed.optional
  end

  def test_to_typescript
    expected_simple = "simpleScores: { [key: string]: number };"
    assert_equal expected_simple, @simple_indexed.to_typescript

    expected_optional = "optionalScores?: { [key: string]: number };"
    assert_equal expected_optional, @optional_indexed.to_typescript

    expected_nested = "nestedScores: { [key: string]: number[] };"
    assert_equal expected_nested, @nested_indexed.to_typescript

    expected_complex = "complexScores: { [key: string]: CustomClass };"
    assert_equal expected_complex, @complex_indexed.to_typescript
  end

  def test_process_value
    input = { a: 1, b: 2 }
    assert_equal input, @simple_indexed.process_value(input)

    nested_input = { a: [1, 2], b: [3, 4] }
    assert_equal nested_input, @nested_indexed.process_value(nested_input)

    complex_input = {
      a: { id: 1, name: "Item A" },
      b: { id: 2, name: "Item B" }
    }
    processed = @complex_indexed.process_value(complex_input)
    assert_equal complex_input, processed
    assert_instance_of Hash, processed[:a]
    assert_instance_of Hash, processed[:b]
  end

  def test_validate_type
    assert_nil Typesmith::IndexedProperty.validate_type(:string)
    assert_nil Typesmith::IndexedProperty.validate_type([:number])

    custom_class = Class.new(Typesmith::Definition)
    assert_nil Typesmith::IndexedProperty.validate_type(custom_class)

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) do
      Typesmith::IndexedProperty.new("invalid", :invalid, :number)
    end

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) do
      Typesmith::IndexedProperty.new("invalid", :string, :invalid)
    end
  end
end
