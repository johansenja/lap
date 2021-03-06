# frozen_string_literal: true

module Lap
  class Module
    include Helpers

    def initialize(node, indent_level = 0)
      @node = node
      @indent_level = indent_level
      @has_contents = !@node.members.empty?
    end

    def render
      self_indent = " " * (Lap::Config[:indent] * @indent_level)
      comment = get_comment(@node)
      "#{comment}#{self_indent}module #{@node.name.name}#{contents}#{self_indent if @has_contents}end\n"
    end

    private

    def contents
      @contents ||= begin
        if @has_contents
          members = @node.members.map do |member|
            case member
            when RBS::AST::Members::MethodDefinition
              Lap::Method.new(member, @indent_level + 1).render
            when RBS::AST::Declarations::Class
              Lap::Class.new(member, @indent_level + 1).render
            when RBS::AST::Declarations::Module
              self.class.new(member, @indent_level + 1).render
            when RBS::AST::Declarations::Constant
              Lap::Constant.new(member, @indent_level + 1).render
            when RBS::AST::Declarations::Alias
              # no-op: not present in ruby
            else
              warn "Unsupported member for modules: #{member}"
            end
          end
          "\n#{members.join("\n")}"
        else
          "; "
        end
      end
    end
  end
end
