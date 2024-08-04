# frozen_string_literal: true

require "zeitwerk"
require "active_support"
require "active_support/core_ext"

module Typesmith
  class Error < StandardError; end
  class << self
    attr_accessor :loader

    def setup
      self.loader = Zeitwerk::Loader.for_gem
      loader.setup
    end
  end
end

Typesmith.setup
