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
      when RBS::Types::Literal
        tipe.inspect
      when ->(tp) { tp.class.to_s.start_with? "RBS::Types::Bases" }
        "# returns #{tipe}"
      else
        "# TODO: return #{tipe.name.name}"
      end
    end

    def arguments
      @arguments ||= begin
        type = @node.types.first.type
        rp = type.required_positionals
        rkw = type.required_keywords
        op = type.optional_positionals
        okw = type.optional_keywords
        args(rp, rkw, op, okw)
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
        else
          block = @node.types.first.block
          return_type = return_type(@node.types.first.type.return_type)
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
      end
    end
  end
end
