# frozen_string_literal: true

module Lap
  class Class
    include Helpers

    def initialize(node, indent_level = 0)
      @node = node
      @indent_level = indent_level
      @has_contents = !@node.members.empty?
    end

    def render
      superclass = @node.super_class ? " < #{@node.super_class.name.name}" : ""
      self_indent = " " * (Lap::Config[:indent] * @indent_level)
      comment = get_comment(@node)
      "#{comment}#{self_indent}class #{@node.name.name}#{superclass}#{contents}#{self_indent if @has_contents}end\n"
    end

    private

    def contents
      @contents ||= begin
        if @has_contents
          member_indent = Lap::Config[:indent] * (@indent_level + 1)
          members = @node.members.map do |m|
            case m
            when RBS::AST::Members::MethodDefinition
              Lap::Method.new(m, @indent_level + 1).render
            when RBS::AST::Declarations::Class
              self.class.new(m, @indent_level + 1).render
            when RBS::AST::Declarations::Module
              Lap::Module.new(m, @indent_level + 1).render
            when RBS::AST::Members::AttrReader
              with_comment(m, "attr_reader :#{m.name}").indent(member_indent)
            when RBS::AST::Members::AttrWriter
              with_comment(m, "attr_writer :#{m.name}").indent(member_indent)
            when RBS::AST::Members::AttrAccessor
              with_comment(m, "attr_accessor :#{m.name}").indent(member_indent)
            when RBS::AST::Members::Public
              "public\n".indent(member_indent)
            when RBS::AST::Members::Private
              "private\n".indent(member_indent)
            when RBS::AST::Members::Include
              with_comment(m, "include #{m.name}").indent(member_indent)
            when RBS::AST::Members::Extend
              with_comment(m, "extend #{m.name}").indent(member_indent)
            when RBS::AST::Declarations::Constant
              Lap::Constant.new(m, @indent_level + 1).render
            when RBS::AST::Declarations::Alias
              # no-op: not present in ruby
            else
              warn "Unsupported member for classes: #{m}"
            end
          end
          "\n#{members.compact.join("\n")}"
        else
          "; "
        end
      end
    end
  end
end
