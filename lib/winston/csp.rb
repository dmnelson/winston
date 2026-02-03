module Winston
  class CSP

    attr_reader :variables, :constraints

    def initialize
      @variables = {}
      @constraints = []
    end

    def solve(solver = nil, **options)
      initial = var_assignments
      return false unless validate_initial_assignments(initial)

      solver_instance = build_solver(solver, options)
      solver_instance.search(initial)
    end

    def add_variable(name, value: nil, domain: nil, &block)
      domain = Domain.new(self, name, domain || block) unless value
      variables[name] = Variable.new(name, value: value, domain: domain)
    end

    def add_constraint(*variables, constraint: nil, allow_nil: false, &block)
      constraint ||= Constraint.new(variables: variables, allow_nil: allow_nil, predicate: block)
      constraints << constraint
    end

    def validate(changed_var, assignments)
      constraints.each do |constraint|
        return false if constraint.elegible_for?(changed_var, assignments) && !constraint.validate(assignments)
      end
      true
    end

    def domain_for(variable_name)
      variable = variables[variable_name]
      return [] if variable.nil? || variable.domain.nil?

      variable.domain.values
    end

    private

    def var_assignments
      @variables.reduce({}) do |assignments, (name, variable)|
        assignments[name] = variable.value unless variable.value.nil?
        assignments
      end
    end

    def build_solver(solver, options)
      return solver if solver && !solver.is_a?(Symbol)

      case solver
      when nil, :backtrack
        Solvers::Backtrack.new(self, **options)
      when :mac
        Solvers::MAC.new(self, **options)
      when :min_conflicts
        Solvers::MinConflicts.new(self, **options)
      else
        raise ArgumentError, "Unknown solver :#{solver}"
      end
    end

    def validate_initial_assignments(assignments)
      constraints.all? do |constraint|
        next constraint.validate(assignments) if constraint.global || constraint.allow_nil
        next true unless constraint.variables.all? { |v| assignments.key?(v) }

        constraint.validate(assignments)
      end
    end
  end
end
