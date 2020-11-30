module Lap
  module Helpers
    CLASS_TO_LITERAL = {
      String: '""',
      Array: '[]',
      Hash: "{}",
    }

    def args(rp, rkw, op, okw)
      if [rp, rkw, op, okw].any? { |arg| arg.length.positive? }
        contents = [
          rp.map { |pos| pos.name || pos.type.name.name.downcase },
          op.map { |pos| "#{pos.name || pos.type.name.name.downcase} = #{CLASS_TO_LITERAL[pos.type.name.name] || "nil"}" },
          rkw.map { |name, _| "#{name}:" },
          okw.map { |name, t| "#{name}: #{CLASS_TO_LITERAL[t.type.name.name]}" },
        ].reject(&:empty?).flatten.join(", ")
        "(#{contents})"
      end
    end

    def with_comment(node, output)
      if (comment = node.comment&.string)
        "#{comment.lines.map { |l| "# #{l}" }.join}#{output}"
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
      lines.each do |l|
        break if l.start_with? "@!begin"

        comment << "# #{l}"
      end

      comment.join
    end
  end
end
