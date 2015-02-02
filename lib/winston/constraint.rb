module Winston
  class Constraint

    def initialize(variables = nil, predicate = nil)
      @variables = variables || []
      @predicate = predicate
      @global = @variables.empty?
    end

    def elegible_for?(changed_var, assignments)
      @global || (@variables.include?(changed_var) && @variables.all? { |v| assignments.key? v })
    end

    def validate(assignments)
      return false unless @predicate
      @predicate.call(*assignments.values_at(*@variables), assignments)
    end
  end
end
