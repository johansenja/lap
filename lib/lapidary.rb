# frozen_string_literal: true

require "rbs"
require "pathname"
require "lapidary/version"
require "lapidary/helpers"
require "lapidary/class"
require "lapidary/method"
require "lapidary/module"
require "pry-byebug"
require "core_ext/string"

module Lapidary
  CONFIG_FILENAME = ".lap.yml"
  DEFAULT_CONFIG = {
    indent: 2
  }
  fp = File.join(File.dirname(__FILE__), "..", CONFIG_FILENAME)
  yml_config = Pathname(fp).exist? ? YAML.safe_load(File.read(fp)) : {}
  Config = DEFAULT_CONFIG.merge(yml_config.transform_keys(&:to_sym))

  class Output
    def initialize(pathname)
      loader = RBS::EnvironmentLoader.new(core_root: nil) # don't pollute the env with ruby stdlib
      loader.add(path: Pathname(pathname))
      @env = RBS::Environment.from_loader(loader).resolve_type_names
    end

    def render
      output = @env.declarations.map do |decl|
        case decl
        when RBS::AST::Declarations::Class
          Lapidary::Class.new(decl).render
        when RBS::AST::Declarations::Module
          Lapidary::Module.new(decl).render
        else
          "TODO: #{decl}"
        end
      end

      puts output.join("\n")
    end
  end
end
