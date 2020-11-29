# frozen_string_literal: true

require "rbs"
require "pathname"
require "lapidary/version"

module Lapidary
  class Output
    def initialize(pathname)
      @pathname, @config = pathname, {
        indent: 2
      }

      loader = RBS::EnvironmentLoader.new(core_root: nil) # don't pollute the env with ruby stdlib
      loader.add(path: Pathname(pathname))
      @env = RBS::Environment.from_loader(loader).resolve_type_names
    end

    def render
      output = @env.declarations.map do |decl|
        case decl
        when RBS::AST::Declarations::Class
          render_class_decl(decl)
        when RBS::AST::Declarations::Module
          render_module_decl(decl)
        else
          "TODO: #{decl}"
        end
      end

      puts output.join("\n")
    end

    private

    def return_type(t)
      case t
      when RBS::Types::Literal
        t
      when ->(t) { t.class.to_s.start_with? "RBS::Types::Bases" }
        "# returns #{t}"
      else
        "# TODO: return #{t.name.name}"
      end
    end

    CLASS_TO_LITERAL = {
      String: '""',
      Array: '[]',
      Hash: "{}",
    }

    def args(rp, rkw, op, okw)
      if [rp, rkw, op, okw].any? { |arg| arg.length.positive? }
        contents = [
          rp.map { |pos| pos.name || pos.type.name.name.downcase },
          op.map { |pos| "#{pos.name || pos.type.name.name.downcase} = #{CLASS_TO_LITERAL[pos.type.name.name]}" },
          rkw.map { |name, _| "#{name}:" },
          okw.map { |name, t| "#{name}: #{CLASS_TO_LITERAL[t.type.name.name] || t.type.name || nil}" },
        ].reject(&:empty?).flatten.join(", ")
        "(#{contents})"
      end
    end

    def render_method_def(m)
      type = m.types.first.type
      rp = type.required_positionals
      rkw = type.required_keywords
      op = type.optional_positionals
      okw = type.optional_keywords
      return_type = return_type(type.return_type)
      <<~METHOD
    #{
      "# #{m.comment.string}" if m.comment
    }def #{"self." unless m.kind == :instance}#{m.name}#{args(rp, rkw, op, okw)}
      #{return_type}
    end
      METHOD
    end

    def render_class_decl(decl, indent_level = 0)
      has_contents = !decl.members.empty?
      contents = if has_contents
                   members = decl.members.map do |m|
                     case m
                     when RBS::AST::Members::MethodDefinition
                       indent(render_method_def(m), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Declarations::Class
                       render_class_decl(m, indent_level + 1)
                     when RBS::AST::Declarations::Module
                       render_module_decl(m, indent_level + 1)
                     else
                       "TODO: #{m}"
                     end
                   end
                   "\n#{members.join("\n")}"
                 else
                   "; "
                 end
      superclass = decl.super_class ? " < #{decl.super_class.name.name}" : ""
      self_indent = " " * (@config[:indent] * indent_level)

      "#{self_indent}class #{decl.name.name}#{superclass}#{contents}#{self_indent if has_contents}end\n"
    end

    def render_module_decl(decl, indent_level = 0)
      has_contents = !decl.members.empty?
      contents = if has_contents
                   members = decl.members.map do |m|
                     case m
                     when RBS::AST::Members::MethodDefinition
                       indent(render_method_def(m), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Declarations::Class
                       render_class_decl(m, indent_level + 1)
                     when RBS::AST::Declarations::Module
                       render_module_decl(m, indent_level + 1)
                     else
                       "TODO: #{m}"
                     end
                   end
                   "\n#{members.join("\n")}"
                 else
                   "; "
                 end

      self_indent = " " * (@config[:indent] * indent_level)
      "#{self_indent}module #{decl.name.name}#{contents}#{self_indent if has_contents}end\n"
    end

    def indent(str, amount)
      str.gsub(/^/, " " * amount)
    end
  end
end
