module Winston
  class Domain
    def initialize(csp, variable, values)
      @csp = csp
      @variable = variable
      @values = values
    end

    def values
      return @values unless @values.is_a?(Proc)
      @values.call(@variable, @csp)
    end
  end
end
