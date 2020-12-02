module Lap
  module Helpers
    CLASS_TO_LITERAL = {
      String: '""',
      Array: '[]',
      Hash: "{}",
    }

    def args(rp, rkw, op, okw)
      if [rp, rkw, op, okw].any? { |arg| arg.length.positive? }
        arg_counter = 1
        contents = [
          rp.map do |pos|
            arg_counter += 1
            pos.name || begin
              if pos.type.respond_to?(:name)
                pos.type.name.name.downcase
              else
                "arg#{arg_counter}"
              end
            end
          end,
          op.map do |pos|
            name = nil
            value = "nil"
            if pos.name
              name = pos.name
            elsif pos.type.respond_to?(:name)
              name = pos.type.name.name.downcase
              value = CLASS_TO_LITERAL[pos.type.name.name]
            else
              name = "arg#{arg_counter}"
            end
            "#{name} = #{value}"
          end,
          rkw.map { |name, _| "#{name}:" },
          okw.map do |name, tipe|
            value = tipe.type.respond_to?(:name) ? CLASS_TO_LITERAL[tipe.type.name.name] : "nil"
            "#{name}: #{value}"
          end,
        ].reject(&:empty?).flatten.join(", ")
        "(#{contents})"
      end
    end

    def with_comment(node, output)
      if (comment = node.comment&.string)
        "#{comment.lines.map { |line| "# #{line}" }.join}#{output}"
      else
        output
      end
    end

    def get_comment(node)
      return nil unless node.comment

      lines = node.comment
                  .string
                  .lines
      comment = []
      lines.each do |line|
        break if line.start_with? "@!begin"

        comment << "# #{line}"
      end

      comment.join
    end
  end
end
