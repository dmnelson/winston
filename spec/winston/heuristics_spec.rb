require "winston"

describe Winston::Heuristics do
  let(:csp) { Winston::CSP.new }

  describe ".mrv" do
    it "picks the variable with the fewest remaining values" do
      csp.add_variable :a, domain: [1, 2, 3]
      csp.add_variable :b, domain: [1, 2]
      csp.add_variable :c, domain: [1, 2, 3]
      csp.add_constraint(:a) { |a| a == 1 }

      vars = csp.variables.each_value.to_a
      chosen = described_class.mrv.call(vars, {}, csp)

      expect(chosen.name).to eq(:a)
    end
  end

  describe ".lcv" do
    it "orders values to leave more options for other variables" do
      csp.add_variable :a, domain: [2, 1]
      csp.add_variable :b, domain: [2, 3]
      csp.add_constraint(:a, :b) { |a, b| b > a }

      values = csp.domain_for(:a)
      ordered = described_class.lcv.call(values, csp.variables[:a], {}, csp)

      expect(ordered).to eq([1, 2])
    end
  end

  describe ".in_order" do
    it "returns values as-is" do
      values = [3, 1, 2]
      ordered = described_class.in_order.call(values, nil, {}, csp)

      expect(ordered).to eq(values)
    end
  end

  describe ".forward_checking" do
    it "returns true to enable forward checking" do
      expect(described_class.forward_checking).to be(true)
    end
  end
end
