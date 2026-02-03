module Winston
  class DSL
    attr_reader :csp

    def initialize(csp = CSP.new)
      @csp = csp
      @domains = {}
    end

    def domain(name, values)
      @domains[name] = values
    end

    def var(name, domain: nil, value: nil, &block)
      resolved_domain = resolve_domain(domain)
      csp.add_variable(name, value: value, domain: resolved_domain, &block)
    end

    def constraint(*variables, allow_nil: false, &block)
      csp.add_constraint(*variables, allow_nil: allow_nil, &block)
    end

    def use_constraint(name, *variables, allow_nil: false, **options)
      factory = constraint_factory_for(name)
      constraint = factory.call(variables, allow_nil, **options)
      csp.add_constraint(constraint: constraint)
    end

    private

    def resolve_domain(domain)
      return domain unless domain.is_a?(Symbol)
      return @domains[domain] if @domains.key?(domain)

      raise ArgumentError, "Unknown domain :#{domain}"
    end

    def constraint_factory_for(name)
      registry = Winston.constraint_registry
      return registry[name] if registry.key?(name)

      raise ArgumentError, "Unknown constraint :#{name}"
    end
  end

  def self.constraint_registry
    @constraint_registry ||= {
      all_different: lambda do |variables, allow_nil, **options|
        Winston::Constraints::AllDifferent.new(variables: variables, allow_nil: allow_nil, **options)
      end,
      not_in_list: lambda do |variables, allow_nil, **options|
        Winston::Constraints::NotInList.new(variables: variables, allow_nil: allow_nil, **options)
      end
    }
  end

  def self.register_constraint(name, factory = nil, &block)
    factory ||= block
    raise ArgumentError, "Constraint factory required for :#{name}" unless factory

    constraint_registry[name] = factory
  end

  def self.define(&block)
    builder = DSL.new
    builder.instance_eval(&block) if block
    builder.csp
  end
end
