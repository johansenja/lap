# frozen_string_literal: true

module Lap
  class Method
    include Helpers

    def initialize(node, indent_level = 0)
      @node = node
      @indent_level = indent_level
    end

    def render
      comment = get_comment(@node)
      result = <<~METHOD
        #{comment}def #{"self." unless @node.kind == :instance}#{@node.name}#{arguments}
          #{body}
        end
      METHOD
      result.indent((Lap::Config[:indent] * @indent_level).to_i)
    end

    private

    def return_type(tipe)
      case tipe
      when RBS::Types::Literal, RBS::Types::Proc, RBS::Types::Tuple, RBS::Types::Record
        tipe.inspect
      when RBS::Types::Bases::Base
        "# returns #{tipe}"
      when RBS::Types::ClassSingleton, RBS::Types::ClassInstance
        "# TODO: return #{tipe.name.name.inspect}"
      else
        # RBS::Types::Union, RBS::Types::Alias, RBS::Types::Optional, RBS::Types::Intersection, RBS::Types::Interface
        "# TODO: return #{tipe.inspect}"
      end
    end

    def arguments
      @arguments ||= begin
        if (first_type = @node.types.first)
          type = first_type.type
          rp = type.required_positionals
          rkw = type.required_keywords
          op = type.optional_positionals
          okw = type.optional_keywords
          args(rp, rkw, op, okw)
        else
          ""
        end
      end
    end

    def body
      @body ||= begin
        comment = @node.comment
        logic = ""
        if comment
          logic = []
          has_logic = false
          comment.string.lines.each do |line|
            if has_logic
              break if line.lstrip.start_with? "@!end"

              logic << line
            elsif line.lstrip.start_with? "@!begin"
              has_logic = true
            end
          end
          logic = logic.join
        end
        if logic.length.positive?
          logic
        elsif (first_type = @node.types.first)
          block = first_type.block
          return_type = return_type(first_type.type.return_type)
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
        else
          "\n"
        end
      end
    end
  end
end
