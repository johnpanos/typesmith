# frozen_string_literal: true

require "minitest/autorun"
require "typesmith"

class DefinitionTest < Minitest::Test
  def setup
    @base_property = Typesmith::BaseProperty.new("test_prop")
  end

  def test_camelized_name
    assert_equal "testProp", @base_property.send(:camelized_name)
  end

  def test_optional_suffix
    assert_equal "", @base_property.send(:optional_suffix)
    optional_prop = Typesmith::BaseProperty.new("test_prop", optional: true)
    assert_equal "?", optional_prop.send(:optional_suffix)
  end

  def test_get_type_string
    assert_equal "string", @base_property.send(:get_type_string, :string)
    assert_equal "number[]", @base_property.send(:get_type_string, [:number])
    assert_equal "{ [key: string]: number }", @base_property.send(:get_type_string, { string: :number })
  end

  def test_validate_type
    assert_nothing_raised { Typesmith::BaseProperty.validate_type(:string) }
    assert_nothing_raised { Typesmith::BaseProperty.validate_type([:number]) }
    assert_nothing_raised { Typesmith::BaseProperty.validate_type({ string: :boolean }) }

    assert_raises(Typesmith::BaseProperty::InvalidTypeError) { Typesmith::BaseProperty.validate_type(:float) }
  end

  class TestSimple < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
    property :is_active, type: :boolean
    property :created_at, type: :Date
    property :tags, type: [:string]
  end

  class TestNested < Typesmith::Definition
    property :user do
      property :id, type: :number
      property :name, type: :string
    end
  end

  class TestIndexed < Typesmith::Definition
    property :scores, type: { string: :number }
  end

  class TestComplex < Typesmith::Definition
    property :id, type: :number
    property :name, type: :string
    property :optional_field, type: :string, optional: true
    property :items, type: [TestSimple]
    property :nested, type: TestNested
    property :metadata, type: { string: :any }
  end

  def test_simple_properties
    typescript = TestSimple.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestSimple {
        id: number;
        name: string;
        isActive: boolean;
        createdAt: Date;
        tags: string[];
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  def test_nested_properties
    typescript = TestNested.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestNested {
        user: {
          id: number;
          name: string;
        };
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  def test_indexed_properties
    typescript = TestIndexed.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestIndexed {
        scores: { [key: string]: number };
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  def test_complex_properties
    typescript = TestComplex.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestComplex {
        id: number;
        name: string;
        optionalField?: string;
        items: TestSimple[];
        nested: TestNested;
        metadata: { [key: string]: any };
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  class TestComplexNesting < Typesmith::Definition
    property :user do
      property :id, type: :number
      property :name, type: :string
      property :address do
        property :street, type: :string
        property :city, type: :string
        property :country do
          property :code, type: :string
          property :name, type: :string
        end
      end
    end
  end

  def test_complex_nesting
    typescript = TestComplexNesting.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestComplexNesting {
        user: {
          id: number;
          name: string;
          address: {
            street: string;
            city: string;
            country: {
              code: string;
              name: string;
            };
          };
        };
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  def test_attribute_processing
    instance = TestComplex.new(
      id: 1,
      name: "Test",
      items: [{ id: 2, name: "Item", is_active: false, created_at: nil, tags: [] }],
      nested: { user: { id: 3, name: "User" } },
      metadata: { key: "value" }
    )

    assert_equal 1, instance.id
    assert_equal "Test", instance.name
    assert_nil instance.optional_field
    assert_equal [{ id: 2, name: "Item", is_active: false, created_at: nil, tags: [] }], instance.items
    assert_equal({ user: { id: 3, name: "User" } }, instance.nested)
    assert_equal({ key: "value" }, instance.metadata)
  end

  def test_missing_required_attribute
    error = assert_raises(ArgumentError) do
      TestComplex.new(name: "Test")
    end
    assert_match(/Missing required attributes: id/, error.message)
  end

  def test_undefined_attribute
    error = assert_raises(Typesmith::Definition::UndefinedAttributeError) do
      TestComplex.new(id: 1, name: "Test", undefined: "value")
    end
    assert_match(/Undefined attributes: undefined/, error.message)
  end

  class TestIndexedArrays < Typesmith::Definition
    property :simple_array, type: { string: [:string] }
    property :complex_array, type: { string: [TestSimple] }
    property :non_array, type: { string: TestSimple }
  end

  def test_indexed_properties_with_arrays
    typescript = TestIndexedArrays.to_typescript
    expected = <<~TYPESCRIPT
      export interface TestIndexedArrays {
        simpleArray: { [key: string]: string[] };
        complexArray: { [key: string]: TestSimple[] };
        nonArray: { [key: string]: TestSimple };
      }
    TYPESCRIPT
    assert_equal expected.strip, typescript
  end

  private

  def assert_nothing_raised(&block)
    block.call
  rescue StandardError => e
    flunk "Expected nothing to be raised, but #{e.class} was raised"
  else
    pass
  end
end
