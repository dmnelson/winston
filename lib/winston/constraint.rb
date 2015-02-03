module Winston
  class Constraint

    attr_reader :variables, :predicate, :allow_nil, :global

    def initialize(variables: nil, predicate: nil, allow_nil: false)
      @variables = [variables].flatten.compact
      @predicate = predicate
      @allow_nil = allow_nil
      @global = @variables.empty?
    end

    def elegible_for?(changed_var, assignments)
      global || (variables.include?(changed_var) && has_required_values?(assignments))
    end

    def validate(assignments)
      return false unless predicate
      predicate.call(*values_at(assignments), assignments)
    end

    protected

    def values_at(assignments)
      assignments.values_at(*variables)
    end

    def has_required_values?(assignments)
      allow_nil || variables.all? { |v| assignments.key?(v) }
    end
  end
end
