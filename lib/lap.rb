# frozen_string_literal: true

require "rbs"
require "pathname"
require "yaml"
require "lap/version"
require "lap/helpers"
require "lap/class"
require "lap/method"
require "lap/module"
require "lap/constant"
require "core_ext/string"

module Lap
  CONFIG_FILENAME = ".lap.yml"
  DEFAULT_CONFIG = {
    indent: 2,
    frozen_string_literals: true,
    preferred_line_length: 100
  }
  FROZEN_STRING_COMMENT = "# frozen_string_literal: true\n\n"
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
          Lap::Class.new(decl).render
        when RBS::AST::Declarations::Module
          Lap::Module.new(decl).render
        else
          warn "TODO: #{decl} not implemented yet"
          nil
        end
      end

      puts FROZEN_STRING_COMMENT if Lap::Config[:frozen_string_literals]
      out = output.join("\n")
      puts out
      out
    end
  end
end
