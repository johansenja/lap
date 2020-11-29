# frozen_string_literal: true

require "rbs"
require "pathname"
require "lapidary/version"
require "pry-byebug"

module Lapidary
  CONFIG_FILENAME = ".lap.yml"
  DEFAULT_CONFIG = {
    indent: 2
  }

  class Output
    def initialize(pathname)
      @pathname = pathname
      fp = File.join(File.dirname(__FILE__), "..", CONFIG_FILENAME)
      yml_config = Pathname(fp).exist? ? YAML.safe_load(File.read(fp)) : {}
      @config = DEFAULT_CONFIG.merge(yml_config.transform_keys(&:to_sym))

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
          okw.map { |name, t| "#{name}: #{CLASS_TO_LITERAL[t.type.name.name]}" },
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
      comment = m.comment
      logic = ""
      if comment
        real_comment = []
        logic = []
        has_logic = false
        comment.string.lines.each do |line|
          if has_logic
            break if line.lstrip.start_with? "@!end"

            logic << line
          elsif line.lstrip.start_with? "@!begin"
            has_logic = true
          else
            real_comment << line
          end
        end
        logic = logic.join
        comment = real_comment.join
      end
      body = logic.length.positive? ? logic : begin
        block = m.types.first.block
        return_type = return_type(type.return_type)
        yld = if block
                bt = block.type
                a = args(
                  bt.required_positionals,
                  bt.required_keywords,
                  bt.optional_positionals,
                  bt.optional_keywords
                )
                "yield#{a}\n"
              end
        "#{yld}#{return_type}"
      end
      with_comment(m, <<~METHOD, comment_string: comment)
        def #{"self." unless m.kind == :instance}#{m.name}#{args(rp, rkw, op, okw)}
          #{body}
        end
      METHOD
    end

    def with_comment(node, output, comment_string: nil)
      if (comment = comment_string || node.comment&.string)
        "#{comment.lines.map { |l| "# #{l}" }.join}#{output}"
      else
        output
      end
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
                     when RBS::AST::Members::AttrReader
                       indent(with_comment(m, "attr_reader :#{m.name}"), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::AttrWriter
                       indent(with_comment(m, "attr_writer :#{m.name}"), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::AttrAccessor
                       indent(with_comment(m, "attr_accessor :#{m.name}"), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::Public
                       indent("public\n", @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::Private
                       indent("private\n", @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::Include
                       indent(with_comment(m, "include #{m.name}"), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Members::Extend
                       indent(with_comment(m, "extend #{m.name}"), @config[:indent] * (indent_level + 1))
                     when RBS::AST::Declarations::Alias
                       # no-op: not present in ruby
                     else
                       warn "TODO: #{m}"
                     end
                   end
                   "\n#{members.compact.join("\n")}"
                 else
                   "; "
                 end
      superclass = decl.super_class ? " < #{decl.super_class.name.name}" : ""
      self_indent = " " * (@config[:indent] * indent_level)

      with_comment(
        decl, "#{self_indent}class #{decl.name.name}#{superclass}#{contents}#{self_indent if has_contents}end\n"
      )
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
                       warn "TODO: #{m}"
                     end
                   end
                   "\n#{members.join("\n")}"
                 else
                   "; "
                 end

      self_indent = " " * (@config[:indent] * indent_level)
      with_comment(
        decl,
        "#{self_indent}module #{decl.name.name}#{contents}#{self_indent if has_contents}end\n",
      )
    end

    def indent(str, amount)
      str.gsub(/^/, " " * amount)
    end
  end
end
