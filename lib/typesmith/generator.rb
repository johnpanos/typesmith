# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "active_support/core_ext/string/inflections"

module Typesmith
  class Generator
    def self.generate_all(base_path: File.join("app", "javascript", "types", "__generated__"))
      new.generate_all(base_path: base_path)
    end

    def generate_all(base_path:)
      @base_path = base_path

      FileUtils.rm_rf(@base_path)

      definition_classes = ObjectSpace.each_object(Class).select { |klass| klass < Definition }.filter(&:name)
      generated_files = definition_classes.map { |klass| generate_typescript_file(klass) }
      generate_index_files(generated_files)

      puts "TypeScript types and index files have been generated in the '#{@base_path}' directory"
    end

    private

    def generate_typescript_file(klass)
      module_path = klass.name.underscore
      directory = File.join(@base_path, File.dirname(module_path))
      FileUtils.mkdir_p(directory)

      file_name = "#{File.basename(module_path)}.ts"
      content = generate_imports(klass)
      content += klass.to_typescript

      full_path = File.join(directory, file_name)
      File.write(full_path, content)
      puts "Generated type for #{klass.name} in #{full_path}"

      { path: full_path, type_name: klass.typescript_type_name }
    end

    def generate_imports(klass)
      imports = Set.new

      klass.properties.each_value do |prop|
        add_import_for_property(imports, prop)
      end

      import_statements = imports.map do |type|
        relative_path = calculate_relative_path(klass.name, type.name)
        "import { #{type.typescript_type_name} } from '#{relative_path}';"
      end

      if import_statements.present?
        "#{import_statements.join("\n")}\n\n"
      else
        ""
      end
    end

    def add_import_for_property(imports, prop)
      case prop
      when SimpleProperty, ArrayProperty
        add_import_for_type(imports, prop.type)
      when IndexedProperty
        add_import_for_type(imports, prop.value_type)
      when NestedProperty
        nested_class = Class.new(Definition)
        nested_class.class_eval(&prop.block)
        nested_class.properties.each_value do |nested_prop|
          add_import_for_property(imports, nested_prop)
        end
      end
    end

    def add_import_for_type(imports, type)
      case type
      when Class
        imports.add(type) if type < Definition
      when Array
        add_import_for_type(imports, type.first)
      when Hash
        add_import_for_type(imports, type.values.first)
      end
    end

    def calculate_relative_path(from_class, to_class)
      from_parts = from_class.underscore.split("/")
      to_parts = to_class.underscore.split("/")

      from_dir = from_parts[0..-2]
      to_dir = to_parts[0..-2]

      common_prefix_length = 0
      from_dir.zip(to_dir).each do |from, to|
        break if from != to

        common_prefix_length += 1
      end

      up_levels = from_dir.length - common_prefix_length
      down_path = to_dir[common_prefix_length..]

      relative_path = [".."] * up_levels + down_path + [to_parts.last]
      "./#{relative_path.join("/")}"
    end

    def generate_index_files(generated_files)
      directories = generated_files.map { |file| File.dirname(file[:path]) }.uniq

      directories.each do |directory|
        files_in_directory = generated_files.select { |file| File.dirname(file[:path]) == directory }

        index_content = files_in_directory.map do |file|
          file_name = File.basename(file[:path], ".ts")
          "export { #{file[:type_name]} } from './#{file_name}';"
        end.join("\n")

        index_path = File.join(directory, "index.ts")
        File.write(index_path, index_content)
        puts "Generated index file in #{index_path}"
      end
    end
  end
end
