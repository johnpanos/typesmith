# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "typesmith"

# Define test classes outside of test methods
class TestSimple < Typesmith::Definition
  property :id, type: :number
  property :name, type: :string
end

class TestNested < Typesmith::Definition
  property :user do
    property :id, type: :number
    property :name, type: :string
  end
end

class TestImport < Typesmith::Definition
  property :simple, type: TestSimple
  property :nested, type: TestNested
end

class TestComplexNesting < Typesmith::Definition
  property :user do
    property :id, type: :number
    property :address do
      property :street, type: :string
      property :city, type: :string
    end
  end
end

class TestIndexed < Typesmith::Definition
  property :scores, type: { string: :number }
end

class TestArray < Typesmith::Definition
  property :items, type: [TestSimple]
end

class Typesmith::GeneratorTest < Minitest::Test
  def setup
    @test_output_dir = File.join("test", "tmp", "generated")
    FileUtils.rm_rf(@test_output_dir)
    FileUtils.mkdir_p(@test_output_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_output_dir)
  end

  def test_generate_all
    Typesmith::Generator.generate_all(base_path: @test_output_dir)

    assert File.exist?(File.join(@test_output_dir, "test_simple.ts"))
    assert File.exist?(File.join(@test_output_dir, "test_nested.ts"))
    assert File.exist?(File.join(@test_output_dir, "index.ts"))

    simple_content = File.read(File.join(@test_output_dir, "test_simple.ts"))
    assert_match(/export interface TestSimple/, simple_content)
    assert_match(/id: number;/, simple_content)
    assert_match(/name: string;/, simple_content)

    nested_content = File.read(File.join(@test_output_dir, "test_nested.ts"))
    assert_match(/export interface TestNested/, nested_content)
    assert_match(/user: {/, nested_content)
    assert_match(/id: number;/, nested_content)
    assert_match(/name: string;/, nested_content)

    index_content = File.read(File.join(@test_output_dir, "index.ts"))
    assert_match(%r{export { TestSimple } from './test_simple';}, index_content)
    assert_match(%r{export { TestNested } from './test_nested';}, index_content)
  end

  def test_generate_imports
    Typesmith::Generator.generate_all(base_path: @test_output_dir)

    import_content = File.read(File.join(@test_output_dir, "test_import.ts"))
    assert_match(%r{import { TestSimple } from './test_simple';}, import_content)
    assert_match(%r{import { TestNested } from './test_nested';}, import_content)
    assert_match(/export interface TestImport/, import_content)
    assert_match(/simple: TestSimple;/, import_content)
    assert_match(/nested: TestNested;/, import_content)
  end

  def test_generate_complex_nesting
    Typesmith::Generator.generate_all(base_path: @test_output_dir)

    complex_content = File.read(File.join(@test_output_dir, "test_complex_nesting.ts"))
    assert_match(/export interface TestComplexNesting/, complex_content)
    assert_match(/user: {/, complex_content)
    assert_match(/id: number;/, complex_content)
    assert_match(/address: {/, complex_content)
    assert_match(/street: string;/, complex_content)
    assert_match(/city: string;/, complex_content)
  end

  def test_generate_indexed_properties
    Typesmith::Generator.generate_all(base_path: @test_output_dir)

    indexed_content = File.read(File.join(@test_output_dir, "test_indexed.ts"))
    assert_match(/export interface TestIndexed/, indexed_content)
    assert_match(/scores: { \[key: string\]: number };/, indexed_content)
  end

  def test_generate_array_properties
    Typesmith::Generator.generate_all(base_path: @test_output_dir)

    array_content = File.read(File.join(@test_output_dir, "test_array.ts"))
    assert_match(%r{import { TestSimple } from './test_simple';}, array_content)
    assert_match(/export interface TestArray/, array_content)
    assert_match(/items: TestSimple\[\];/, array_content)
  end
end
