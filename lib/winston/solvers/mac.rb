require "set"

module Winston
  module Solvers
    class MAC
      def initialize(csp, variable_strategy: :mrv, value_strategy: :in_order)
        @csp = csp
        @variable_strategy = variable_strategy
        @value_strategy = value_strategy
        @neighbors = build_neighbors
        @binary_constraints = build_binary_constraints
        @binary_predicates = build_binary_predicates
        @unary_constraints = build_unary_constraints
        @constraints_for_var = build_constraints_for_var
        @all_different_constraints = build_all_different_constraints
        @all_different_propagator = AllDifferentPropagator.new
      end

      def search(assignments = {})
        domains = initial_domains(assignments)
        return false if domains.nil?

        trail = []
        return false unless propagate_all_different(domains, trail)
        return false unless ac3(domains, assignments, all_arcs, trail)
        return false unless propagate_all_different(domains, trail)

        search_with_domains(assignments, domains, trail)
      end

      private

      attr_reader :csp,
                  :variable_strategy,
                  :value_strategy,
                  :neighbors,
                  :binary_constraints,
                  :binary_predicates,
                  :unary_constraints,
                  :constraints_for_var,
                  :all_different_constraints,
                  :all_different_propagator

      def search_with_domains(assignments, domains, trail)
        return assignments if complete?(assignments)

        var = select_unassigned_variable(assignments, domains)
        values_for(var, domains, assignments).each do |value|
          assigned = assignments.merge(var.name => value)
          next unless consistent_with_constraints(var.name, value, assignments)

          mark = trail.length
          assign_domain(var.name, value, domains, trail)
          next unless propagate_all_different(domains, trail)
          next unless ac3(domains, assigned, arcs_from(var.name), trail)
          next unless propagate_all_different(domains, trail)

          result = search_with_domains(assigned, domains, trail)
          return result if result

          restore(domains, trail, mark)
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
          allowed = domains[name].select do |value|
            with_assignment(assignments, name, value) do
              constraints.all? { |constraint| constraint.validate(assignments) }
            end
          end
          return false if allowed.empty?

          domains[name] = allowed
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
          score = other_vars.sum do |other|
            domains[other.name].count do |other_value|
              with_assignment(assignments, var.name, value) do
                with_assignment(assignments, other.name, other_value) do
                  csp.validate(other.name, assignments)
                end
              end
            end
          end
          [value, score]
        end
        scored.sort_by { |(_, score)| -score }.map(&:first)
      end

      def unassigned_variables(assignments)
        csp.variables.reject { |k, _| assignments.include?(k) }.each_value.to_a
      end

      def ac3(domains, assignments, queue = nil, trail = nil)
        queue ||= all_arcs
        queue = queue.dup
        idx = 0
        while idx < queue.length
          xi, xj = queue[idx]
          idx += 1
          if revise(domains, assignments, xi, xj, trail)
            return false if domains[xi].empty?
            neighbors[xi].each do |xk|
              next if xk == xj
              queue << [xk, xi]
            end
          end
        end
        true
      end

      def revise(domains, assignments, xi, xj, trail)
        constraints = binary_constraints[[xi, xj]]
        predicates = binary_predicates[[xi, xj]]
        constraints ||= []
        predicates ||= []
        return false if constraints.empty? && predicates.empty?

        revised = false
        domains[xi].dup.each do |x|
          supported = domains[xj].any? do |y|
            fast_ok = predicates_satisfied?(predicates, x, y)
            next false unless fast_ok

            with_assignment(assignments, xi, x) do
              with_assignment(assignments, xj, y) do
                constraints.all? { |constraint| constraint.validate(assignments) }
              end
            end
          end
          next if supported

          remove_value(domains, xi, x, trail)
          revised = true
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
        (neighbors[var_name] || []).map { |neighbor| [neighbor, var_name] }
      end

      def build_neighbors
        map = Hash.new { |h, k| h[k] = Set.new }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 2
          a, b = vars
          map[a] << b
          map[b] << a
        end
        map.transform_values(&:to_a)
      end

      def build_binary_constraints
        map = Hash.new { |h, k| h[k] = [] }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 2
          next if direct_predicate?(constraint)
          a, b = vars
          map[[a, b]] << constraint
          map[[b, a]] << constraint
        end
        map
      end

      def build_binary_predicates
        map = Hash.new { |h, k| h[k] = [] }
        csp.constraints.each do |constraint|
          vars = constraint.variables
          next unless vars.size == 2
          next unless direct_predicate?(constraint)
          a, b = vars
          predicate = constraint.predicate
          map[[a, b]] << predicate
          map[[b, a]] << ->(x, y) { predicate.call(y, x) }
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

      def build_all_different_constraints
        csp.constraints.select { |constraint| constraint.is_a?(Winston::Constraints::AllDifferent) }
      end

      def build_constraints_for_var
        map = Hash.new { |h, k| h[k] = [] }
        csp.variables.each_key { |name| map[name] = [] }

        csp.constraints.each do |constraint|
          if constraint.global
            csp.variables.each_key { |name| map[name] << constraint }
          else
            constraint.variables.each { |name| map[name] << constraint }
          end
        end

        map
      end

      def direct_predicate?(constraint)
        constraint.is_a?(Winston::Constraint) &&
          constraint.predicate &&
          constraint.predicate.arity <= 2
      end

      def predicates_satisfied?(predicates, x, y)
        predicates.all? { |predicate| predicate.call(x, y) }
      end

      def consistent_with_constraints(var_name, value, assignments)
        with_assignment(assignments, var_name, value) do
          constraints_for_var[var_name].all? do |constraint|
            if constraint.global
              assignments.size == csp.variables.size ? constraint.validate(assignments) : true
            else
              !constraint.elegible_for?(var_name, assignments) || constraint.validate(assignments)
            end
          end
        end
      end

      def assign_domain(var_name, value, domains, trail)
        return if domains[var_name].size == 1 && domains[var_name].first == value

        trail << [:domain, var_name, domains[var_name]]
        domains[var_name] = [value]
      end

      def propagate_all_different(domains, trail)
        all_different_constraints.each do |constraint|
          vars = constraint.variables
          next if vars.empty?
          return false unless all_different_propagator.gac(domains, trail, vars)
        end
        true
      end

      def with_assignment(assignments, var_name, value)
        had = assignments.key?(var_name)
        previous = assignments[var_name]
        assignments[var_name] = value
        yield
      ensure
        had ? assignments[var_name] = previous : assignments.delete(var_name)
      end

      def remove_value(domains, var_name, value, trail)
        idx = domains[var_name].index(value)
        return if idx.nil?

        trail << [:value, var_name, value, idx]
        domains[var_name].delete_at(idx)
      end

      def restore(domains, trail, mark)
        while trail.length > mark
          entry = trail.pop
          if entry.first == :domain
            _type, var_name, previous = entry
            domains[var_name] = previous
          else
            _type, var_name, value, idx = entry
            domains[var_name].insert(idx, value)
          end
        end
      end

      class AllDifferentPropagator
        def gac(domains, trail, vars)
          values = vars.flat_map { |name| domains[name] }.uniq
          return false if values.empty?

          value_index = {}
          values.each_with_index { |value, idx| value_index[value] = idx }
          adj = vars.map { |name| domains[name].map { |v| value_index[v] } }

          matching = maximum_matching(adj, values.length)
          return false if matching[:size] < vars.length

          graph = build_regin_graph(adj, matching[:pair_u], values.length)
          reachable = regin_reachable_from_free_values(graph, matching[:pair_v])
          scc = tarjan_scc(graph)

          vars.each_with_index do |name, var_idx|
            domains[name].dup.each do |value|
              val_idx = value_index[value]
              next if matching[:pair_u][var_idx] == val_idx
              if reachable[var_idx] || scc[var_idx] == scc[value_node(var_idx, val_idx, vars.length)]
                next
              end

              remove_value(domains, name, value, trail)
              return false if domains[name].empty?
            end
          end

          true
        end

        private

        def value_node(_var_idx, val_idx, var_count)
          var_count + val_idx
        end

        def build_regin_graph(adj, pair_u, value_count)
          var_count = adj.length
          total_nodes = var_count + value_count
          graph = Array.new(total_nodes) { [] }

          adj.each_with_index do |values, var_idx|
            values.each do |val_idx|
              v_node = value_node(var_idx, val_idx, var_count)
              if pair_u[var_idx] == val_idx
                graph[v_node] << var_idx
              else
                graph[var_idx] << v_node
              end
            end
          end

          graph
        end

        def regin_reachable_from_free_values(graph, pair_v)
          var_count = graph.length - pair_v.length
          visited = Array.new(graph.length, false)
          queue = []

          pair_v.each_with_index do |matched_var, val_idx|
            next unless matched_var == -1
            node = var_count + val_idx
            visited[node] = true
            queue << node
          end

          idx = 0
          while idx < queue.length
            node = queue[idx]
            idx += 1
            graph[node].each do |nxt|
              next if visited[nxt]
              visited[nxt] = true
              queue << nxt
            end
          end

          visited
        end

        def tarjan_scc(graph)
          index = 0
          stack = []
          on_stack = Array.new(graph.length, false)
          indices = Array.new(graph.length, -1)
          lowlinks = Array.new(graph.length, 0)
          scc_id = Array.new(graph.length, -1)
          current_scc = 0

          strongconnect = lambda do |v|
            indices[v] = index
            lowlinks[v] = index
            index += 1
            stack << v
            on_stack[v] = true

            graph[v].each do |w|
              if indices[w] == -1
                strongconnect.call(w)
                lowlinks[v] = [lowlinks[v], lowlinks[w]].min
              elsif on_stack[w]
                lowlinks[v] = [lowlinks[v], indices[w]].min
              end
            end

            if lowlinks[v] == indices[v]
              loop do
                w = stack.pop
                on_stack[w] = false
                scc_id[w] = current_scc
                break if w == v
              end
              current_scc += 1
            end
          end

          graph.length.times do |v|
            strongconnect.call(v) if indices[v] == -1
          end

          scc_id
        end

        def maximum_matching(adj, value_count)
          n = adj.length
          pair_u = Array.new(n, -1)
          pair_v = Array.new(value_count, -1)
          dist = Array.new(n)

          bfs = lambda do
            queue = []
            n.times do |u|
              if pair_u[u] == -1
                dist[u] = 0
                queue << u
              else
                dist[u] = nil
              end
            end

            found = false
            idx = 0
            while idx < queue.length
              u = queue[idx]
              idx += 1
              adj[u].each do |v|
                pu = pair_v[v]
                if pu != -1 && dist[pu].nil?
                  dist[pu] = dist[u] + 1
                  queue << pu
                elsif pu == -1
                  found = true
                end
              end
            end
            found
          end

          dfs = lambda do |u|
            adj[u].each do |v|
              pu = pair_v[v]
              if pu == -1 || (dist[pu] == dist[u] + 1 && dfs.call(pu))
                pair_u[u] = v
                pair_v[v] = u
                return true
              end
            end
            dist[u] = nil
            false
          end

          while bfs.call
            n.times do |u|
              dfs.call(u) if pair_u[u] == -1
            end
          end

          size = pair_u.count { |v| v != -1 }
          { size: size, pair_u: pair_u, pair_v: pair_v }
        end

        def remove_value(domains, var_name, value, trail)
          idx = domains[var_name].index(value)
          return if idx.nil?

          trail << [:value, var_name, value, idx]
          domains[var_name].delete_at(idx)
        end
      end
    end
  end
end
