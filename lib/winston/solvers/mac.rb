module Winston
  module Solvers
    class MAC
      def initialize(csp, variable_strategy: :mrv, value_strategy: :in_order)
        @csp = csp
        @variable_strategy = variable_strategy
        @value_strategy = value_strategy
        @neighbors = build_neighbors
        @binary_constraints = build_binary_constraints
        @unary_constraints = build_unary_constraints
      end

      def search(assignments = {})
        domains = initial_domains(assignments)
        return false if domains.nil?

        search_with_domains(assignments, domains)
      end

      private

      attr_reader :csp, :variable_strategy, :value_strategy, :neighbors, :binary_constraints, :unary_constraints

      def search_with_domains(assignments, domains)
        return assignments if complete?(assignments)

        var = select_unassigned_variable(assignments, domains)
        values_for(var, domains, assignments).each do |value|
          assigned = assignments.merge(var.name => value)
          next unless csp.validate(var.name, assigned)

          new_domains = copy_domains(domains)
          new_domains[var.name] = [value]
          next unless ac3(new_domains, assigned, arcs_from(var.name))

          result = search_with_domains(assigned, new_domains)
          return result if result
        end

        false
      end

      def complete?(assignments)
        assignments.size == csp.variables.size
      end

      def initial_domains(assignments)
        domains = {}
        csp.variables.each do |name, variable|
          if assignments.key?(name)
            domains[name] = [assignments[name]]
          elsif !variable.value.nil?
            domains[name] = [variable.value]
          else
            values = csp.domain_for(name)
            return nil if values.empty?
            domains[name] = values.dup
          end
        end

        prune_unary(domains, assignments) ? domains : nil
      end

      def prune_unary(domains, assignments)
        unary_constraints.each do |name, constraints|
          next unless domains.key?(name)
          filtered = domains[name].select do |value|
            candidate = assignments.merge(name => value)
            constraints.all? { |constraint| constraint.validate(candidate) }
          end
          domains[name] = filtered
          return false if filtered.empty?
        end
        true
      end

      def select_unassigned_variable(assignments, domains)
        vars = unassigned_variables(assignments)
        return vars.first if variable_strategy == :first
        return variable_strategy.call(vars, assignments, csp) if variable_strategy.respond_to?(:call)
        return vars.min_by { |var| domains[var.name].size } if variable_strategy == :mrv

        vars.first
      end

      def values_for(var, domains, assignments)
        values = domains[var.name]
        return values if value_strategy == :in_order
        return value_strategy.call(values, var, assignments, csp) if value_strategy.respond_to?(:call)
        return order_lcv(values, var, assignments, domains) if value_strategy == :lcv

        values
      end

      def order_lcv(values, var, assignments, domains)
        other_vars = unassigned_variables(assignments).reject { |v| v.name == var.name }
        scored = values.map do |value|
          candidate = assignments.merge(var.name => value)
          score = other_vars.sum do |other|
            domains[other.name].count do |other_value|
              csp.validate(other.name, candidate.merge(other.name => other_value))
            end
          end
          [value, score]
        end
        scored.sort_by { |(_, score)| -score }.map(&:first)
      end

      def unassigned_variables(assignments)
        csp.variables.reject { |k, _| assignments.include?(k) }.each_value.to_a
      end

      def ac3(domains, assignments, queue = nil)
        queue ||= all_arcs
        queue = queue.dup
        until queue.empty?
          xi, xj = queue.shift
          if revise(domains, assignments, xi, xj)
            return false if domains[xi].empty?
            neighbors[xi].each do |xk|
              next if xk == xj
              queue << [xk, xi]
            end
          end
        end
        true
      end

      def revise(domains, assignments, xi, xj)
        constraints = binary_constraints[[xi, xj]]
        return false if constraints.empty?

        revised = false
        domains[xi] = domains[xi].select do |x|
          supported = domains[xj].any? do |y|
            candidate = assignments.merge(xi => x, xj => y)
            constraints.all? { |constraint| constraint.validate(candidate) }
          end
          revised = true unless supported
          supported
        end
        revised
      end

      def all_arcs
        arcs = []
        neighbors.each do |xi, list|
          list.each { |xj| arcs << [xi, xj] }
        end
        arcs
      end

      def arcs_from(var_name)
        neighbors[var_name].map { |neighbor| [neighbor, var_name] }
      end

      def build_neighbors
        map = Hash.new { |h, k| h[k] = [] }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 2
          a, b = vars
          map[a] << b
          map[b] << a
        end
        map
      end

      def build_binary_constraints
        map = Hash.new { |h, k| h[k] = [] }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 2
          a, b = vars
          map[[a, b]] << constraint
          map[[b, a]] << constraint
        end
        map
      end

      def build_unary_constraints
        map = Hash.new { |h, k| h[k] = [] }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 1
          map[vars.first] << constraint
        end
        map
      end

      def copy_domains(domains)
        domains.transform_values(&:dup)
      end
    end
  end
end
