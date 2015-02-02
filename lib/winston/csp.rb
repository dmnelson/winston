module Winston
  class CSP

    attr_reader :variables, :constraints

    def initialize
      @variables = {}
      @constraints = []
    end

    def solve(solver = Backtrack.new(self))
      solver.search(var_assignments)
    end

    def add_variable(name, value: nil, domain: nil, &block)
      domain = Domain.new(self, name, domain || block) unless value
      variables[name] = Variable.new(name, value: value, domain: domain)
    end

    def add_constraint(*variables, constraint: nil, &block)
      constraint ||= Constraint.new(variables, block)
      constraints << constraint
    end

    def validate(changed_var, assignments)
      constraints.each do |constraint|
        return false if constraint.elegible_for?(changed_var, assignments) && !constraint.validate(assignments)
      end
      true
    end

    private

    def var_assignments
      @variables.reduce({}) do |assignments, (name, variable)|
        assignments[name] = variable.value unless variable.value.nil?
        assignments
      end
    end
  end
end
