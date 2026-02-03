module Winston
  class Backtrack
    def initialize(csp, variable_strategy: :first, value_strategy: :in_order, forward_checking: false)
      @csp = csp
      @variable_strategy = variable_strategy
      @value_strategy = value_strategy
      @forward_checking = forward_checking
    end

    def search(assignments = {})
      return assignments if complete?(assignments)
      var = select_unassigned_variable(assignments)
      domain_values(var, assignments).each do |value|
        assigned = assignments.merge(var.name => value)
        if valid?(var.name, assigned)
          result = search(assigned)
          return result if result
        end
      end
      false
    end

    private

    attr_reader :csp, :variable_strategy, :value_strategy, :forward_checking

    def complete?(assignments)
      assignments.size == csp.variables.size
    end

    def valid?(changed, assignments)
      return false unless csp.validate(changed, assignments)
      return true unless forward_checking

      forward_check(assignments)
    end

    def select_unassigned_variable(assignments)
      vars = unassigned_variables(assignments)
      return vars.first if variable_strategy == :first
      return variable_strategy.call(vars, assignments, csp) if variable_strategy.respond_to?(:call)
      return vars.min_by { |var| remaining_values(var, assignments).size } if variable_strategy == :mrv

      vars.first
    end

    def domain_values(var, assignments)
      values = remaining_values(var, assignments)
      return values if value_strategy == :in_order
      return value_strategy.call(values, var, assignments, csp) if value_strategy.respond_to?(:call)
      return order_lcv(values, var, assignments) if value_strategy == :lcv

      values
    end

    def remaining_values(var, assignments)
      csp.domain_for(var.name).select do |value|
        csp.validate(var.name, assignments.merge(var.name => value))
      end
    end

    def order_lcv(values, var, assignments)
      other_vars = unassigned_variables(assignments).reject { |v| v.name == var.name }
      scored = values.map do |value|
        score = other_vars.sum do |other|
          csp.domain_for(other.name).count do |other_value|
            csp.validate(other.name, assignments.merge(var.name => value, other.name => other_value))
          end
        end
        [value, score]
      end
      scored.sort_by { |(_, score)| -score }.map(&:first)
    end

    def unassigned_variables(assignments)
      csp.variables.reject { |k, _| assignments.include?(k) }.each_value.to_a
    end

    def forward_check(assignments)
      unassigned_variables(assignments).all? do |var|
        csp.domain_for(var.name).any? do |value|
          csp.validate(var.name, assignments.merge(var.name => value))
        end
      end
    end
  end
end
