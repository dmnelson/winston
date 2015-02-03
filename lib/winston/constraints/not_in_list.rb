module Winston
  module Constraints
    class NotInList < Winston::Constraint

      attr_reader :list

      def initialize(variables: nil, allow_nil: false, list: [])
        super(variables: variables, allow_nil: allow_nil)
        @list = list
      end

      def validate(assignments)
        values = global ? assignments.values : values_at(assignments)
        !values.any? { |v| list.include?(v) }
      end
    end
  end
end
