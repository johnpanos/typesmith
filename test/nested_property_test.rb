# frozen_string_literal: true

require "minitest/autorun"
require "typesmith"

class NestedPropertyTest < Minitest::Test
  class SimpleNested < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
  end

  def setup
    @simple_nested = Typesmith::NestedProperty.new("simple_nested", proc {
      property :id, type: :number
      property :name, type: :string
    })

    @optional_nested = Typesmith::NestedProperty.new("optional_nested", proc {
      property :id, type: :number
      property :name, type: :string
    }, optional: true)

    @complex_nested = Typesmith::NestedProperty.new("complex_nested", proc {
      property :id, type: :number
      property :nested, type: SimpleNested
      property :array_prop, type: [:string]
    })
  end

  def test_initialization
    assert_equal "simple_nested", @simple_nested.name
    refute @simple_nested.optional
    assert @optional_nested.optional
    assert_instance_of Proc, @simple_nested.block
  end

  def test_to_typescript
    expected_simple = <<~TYPESCRIPT.chomp
      simpleNested: {
        id: number;
        name: string;
      };
    TYPESCRIPT
    assert_equal expected_simple, @simple_nested.to_typescript

    expected_optional = <<~TYPESCRIPT.chomp
      optionalNested?: {
        id: number;
        name: string;
      };
    TYPESCRIPT
    assert_equal expected_optional, @optional_nested.to_typescript

    expected_complex = <<~TYPESCRIPT.chomp
      complexNested: {
        id: number;
        nested: SimpleNested;
        arrayProp: string[];
      };
    TYPESCRIPT
    assert_equal expected_complex, @complex_nested.to_typescript
  end

  def test_process_value
    simple_input = { id: 1, name: "Test" }
    processed_simple = @simple_nested.process_value(simple_input)
    assert_equal simple_input, processed_simple

    complex_input = {
      id: 1,
      nested: { id: 2, name: "Nested" },
      array_prop: %w[a b c]
    }
    processed_complex = @complex_nested.process_value(complex_input)
    assert_equal complex_input, processed_complex
    assert_instance_of Hash, processed_complex[:nested]
    assert_instance_of Array, processed_complex[:array_prop]
  end
end
