require "winston"

describe "Numbers Example" do
  let(:csp) { Winston::CSP.new }

  describe "'a' has to be double of 'c' and higher than 'b', 'b' has to be even and higher than 'c'" do
    before do
      csp.add_variable :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]

      csp.add_constraint(:a, :c) { |a, c| a == c * 2 }
      csp.add_constraint(:a, :b) { |a, b| a > b }
      csp.add_constraint(:b, :c) { |b, c| b > c }
      csp.add_constraint(:b) { |b| b % 2 == 0 }
    end

    it "should return a valid solution" do
      expect(csp.solve).to eq(a: 6, b: 4, c: 3)
    end
  end

  describe "has to have different values" do
    before do
      csp.add_variable :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :d, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
      csp.add_variable :e, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]

      csp.add_constraint constraint: Winston::Constraints::AllDifferent.new
    end

    it "should return a valid solution" do
      expect(csp.solve).to eq(a: 1, b: 2, c: 3, d: 4, e: 5)
    end
  end
end
