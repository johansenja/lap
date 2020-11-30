# frozen_string_literal: true

module Lap
  class Constant
    def initialize(node, indent_level)
      @node = node
      @indent_level = indent_level
    end

    def render
      "#{name} = #{value}".indent(Lap::Config[:indent] * @indent_level)
    end

    private

    def name
      @node.name.name
    end

    def value
      case @node.type
      when RBS::Types::Record
        fields = @node.type.fields
        content = if fields.empty?
                    nil
                  else
                    " #{record_contents(fields)} "
                  end
        "{#{content}}"
      end
    end

    def record_contents(hsh)
      inner_length = 0
      contents = hsh.map do |k, v|
        val = case v
              when RBS::Types::Literal
                v.literal
              else
                "nil"
              end
        pair = k.is_a?(Symbol) ? "#{k}: #{val}" : "#{k} => #{val}"
        inner_length += pair.length
        pair
      end

      if inner_length > Lap::Config[:preferred_line_length]
        "\n#{contents.join(",\n")}\n"
      else
        contents.join(", ")
      end
    end
  end
end
