require "winston"

describe Winston::DSL do
  describe ".define" do
    it "builds a CSP with variables and constraints" do
      csp = Winston.define do
        var :a, domain: [1, 2, 3]
        var :b, domain: [1, 2, 3]
        constraint(:a, :b) { |a, b| a > b }
      end

      expect(csp.solve).to eq({ a: 2, b: 1 })
    end

    it "supports named domains" do
      csp = Winston.define do
        domain :digits, [1, 2, 3]
        var :a, domain: :digits
        var :b, domain: :digits
        constraint(:a, :b) { |a, b| a != b }
      end

      result = csp.solve
      expect([1, 2, 3]).to include(result[:a])
      expect([1, 2, 3]).to include(result[:b])
      expect(result[:a]).to_not eq(result[:b])
    end

    it "uses named constraints via use_constraint" do
      csp = Winston.define do
        var :a, domain: [1, 2]
        var :b, domain: [1, 2]
        use_constraint :all_different, :a, :b
      end

      expect(csp.solve).to eq({ a: 1, b: 2 })
    end

    it "passes options to named constraints" do
      csp = Winston.define do
        var :a, domain: [1, 2, 3]
        use_constraint :not_in_list, :a, list: [1, 2]
      end

      expect(csp.solve).to eq({ a: 3 })
    end
  end

  describe ".register_constraint" do
    it "registers and uses a custom constraint by name" do
      custom = Class.new(Winston::Constraint) do
        def validate(assignments)
          values = values_at(assignments)
          values.all? { |v| v == 2 }
        end
      end

      Winston.register_constraint(:all_twos) do |variables, allow_nil, **_options|
        custom.new(variables: variables, allow_nil: allow_nil)
      end

      csp = Winston.define do
        var :a, domain: [1, 2]
        var :b, domain: [1, 2]
        use_constraint :all_twos, :a, :b
      end

      expect(csp.solve).to eq({ a: 2, b: 2 })
    end
  end
end
