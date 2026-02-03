require "winston"

describe Winston::Solvers::MinConflicts do
  let(:csp) { Winston::CSP.new }

  def valid_solution?(csp, assignments)
    csp.constraints.all? { |constraint| constraint.validate(assignments) }
  end

  it "finds a valid solution for a simple problem" do
    csp.add_variable :a, domain: [1, 2, 3]
    csp.add_variable :b, domain: [1, 2, 3]
    csp.add_variable :c, domain: [1, 2, 3]
    csp.add_constraint(:a, :b) { |a, b| a > b }
    csp.add_constraint(:b, :c) { |b, c| b > c }

    solver = described_class.new(csp, max_steps: 1_000, random: Random.new(1))
    result = solver.search

    expect(result).to be_a(Hash)
    expect(valid_solution?(csp, result)).to be(true)
  end

  it "respects preset assignments" do
    csp.add_variable :a, value: 2
    csp.add_variable :b, domain: [1, 2, 3]
    csp.add_constraint(:a, :b) { |a, b| a > b }

    solver = described_class.new(csp, max_steps: 1_000, random: Random.new(1))
    result = solver.search

    expect(result[:a]).to eq(2)
    expect(valid_solution?(csp, result)).to be(true)
  end

  it "returns false when no solution is found within max_steps" do
    csp.add_variable :a, domain: [1]
    csp.add_variable :b, domain: [1]
    csp.add_constraint(:a, :b) { |a, b| a != b }

    solver = described_class.new(csp, max_steps: 10, random: Random.new(1))
    expect(solver.search).to be(false)
  end
end
