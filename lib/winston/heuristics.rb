module Winston
  module Heuristics
    def self.mrv
      lambda do |vars, assignments, csp|
        vars.min_by { |var| remaining_values(var, assignments, csp).size }
      end
    end

    def self.lcv
      lambda do |values, var, assignments, csp|
        other_vars = vars_without(var, assignments, csp)
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
    end

    def self.in_order
      ->(values, _var, _assignments, _csp) { values }
    end

    def self.forward_checking
      true
    end

    def self.remaining_values(var, assignments, csp)
      csp.domain_for(var.name).select do |value|
        csp.validate(var.name, assignments.merge(var.name => value))
      end
    end

    def self.vars_without(var, assignments, csp)
      csp.variables.reject { |k, _| assignments.include?(k) || k == var.name }.each_value.to_a
    end

    private_class_method :remaining_values, :vars_without
  end
end
