module Winston
  module Constraints
    class AllDifferent < Winston::Constraint
      def validate(assignments)
        assignments.values.uniq.size == assignments.size
      end
    end
  end
end
