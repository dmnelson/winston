module Winston
  module Solvers
    class MinConflicts
    def initialize(csp, max_steps: 10_000, random: Random.new)
      @csp = csp
      @max_steps = max_steps
      @random = random
    end

    def search(assignments = {})
      @fixed_names = fixed_variables(assignments)
      preset = preset_assignments(assignments)
      return false if preset.nil?

      current = preset

      max_steps.times do
        return current if total_conflicts(current).zero?

        conflicted = conflicted_variables(current)
        return false if conflicted.empty?

        var = conflicted[random.rand(conflicted.size)]
        current[var.name] = best_value_for(var, current)
      end

      false
    end

    private

    attr_reader :csp, :max_steps, :random, :fixed_names

    def preset_assignments(assignments)
      preset = {}
      csp.variables.each do |name, variable|
        value = assignments.key?(name) ? assignments[name] : variable.value
        if value.nil?
          domain = csp.domain_for(name)
          return nil if domain.empty?
          value = domain[random.rand(domain.size)]
        end
        preset[name] = value
      end
      preset
    end

    def total_conflicts(assignments)
      csp.constraints.count { |constraint| !constraint.validate(assignments) }
    end

    def conflicted_variables(assignments)
      csp.variables.values.reject do |var|
        fixed?(var) || conflicts_for(var, assignments).zero?
      end
    end

    def fixed?(var)
      fixed_names.include?(var.name)
    end

    def conflicts_for(var, assignments)
      csp.constraints.count do |constraint|
        affects_var = constraint.global || constraint.variables.include?(var.name)
        affects_var && !constraint.validate(assignments)
      end
    end

    def best_value_for(var, assignments)
      domain = csp.domain_for(var.name)
      scored = domain.map do |value|
        candidate = assignments.merge(var.name => value)
        [value, conflicts_for(var, candidate)]
      end
      min = scored.map(&:last).min
      best = scored.select { |(_, score)| score == min }.map(&:first)
      best[random.rand(best.size)]
    end

    def fixed_variables(assignments)
      fixed = assignments.select { |_name, value| !value.nil? }.keys
      csp.variables.each_value do |var|
        fixed << var.name unless var.value.nil?
      end
      fixed.uniq
    end
    end
  end

  MinConflicts = Solvers::MinConflicts
end
