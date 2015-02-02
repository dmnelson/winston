module Winston
  class Variable
    attr_reader :name, :value, :domain
    attr_writer :value

    def initialize(name, value:, domain:)
      @name = name
      @value = value
      @domain = domain
    end
  end
end
