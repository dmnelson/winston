module Winston
  class Backtrack
    def initialize(csp)
      @csp = csp
    end

    def search(assignments = {})
      return assignments if complete?(assignments)
      var = select_unassigned_variable(assignments)
      domain_values(var).each do |value|
        assigned = assignments.merge(var.name => value)
        if valid?(var.name, assigned)
          result = search(assigned)
          return result if result
        end
      end
      false
    end

    private

    attr_reader :csp

    def complete?(assignments)
      assignments.size == csp.variables.size
    end

    def valid?(changed, assignments)
      csp.validate(changed, assignments)
    end

    def select_unassigned_variable(assignments)
      csp.variables.reject { |k,v| assignments.include?(k) }.each_value.first
    end

    def domain_values(var)
      csp.variables[var.name].domain.values
    end
  end
end
