module Winston
  module Constraints
    class AllDifferent < Winston::Constraint
      def validate(assignments)
        values = global ? assignments.values : values_at(assignments).compact
        values.uniq.size == values.size
      end
    end
  end
end
