require "winston"

describe Winston::CSP do
  subject { described_class.new }

  describe "#add_variable" do
    let(:domain) { double("Domain") }

    it "should add variable definitions to the problem" do
      expect(Winston::Domain).to_not receive(:new)
      subject.add_variable :a, value: 1
      expect(subject.variables[:a]).to have_attributes(value: 1, domain: nil)
    end

    it "should add without value and a static domain when it is given" do
      expect(Winston::Domain).to receive(:new).with(subject, :b, [2, 3]).once.and_return(domain)
      subject.add_variable :b, domain: [2, 3]
      expect(subject.variables[:b]).to have_attributes(value: nil, domain: domain)
    end

    it "should add without value and a dynamic domain when it is given" do
      expect(Winston::Domain).to receive(:new).with(subject, :c, an_instance_of(Proc)).once
      subject.add_variable(:c) { |csp| [2, 3, 4] }
      expect(subject.variables[:c]).to have_attributes(value: nil)
    end
  end

  describe "#add_constraint" do
    let(:constraint) { double("Constraint") }
    it "should build a constraint for the given block" do
      expect(Winston::Constraint).to receive(:new).with([:a, :b], an_instance_of(Proc)).once.and_return(constraint)
      subject.add_constraint(:a, :b) { true }
      expect(subject.constraints).to include(constraint)
    end

    it "should add the already build constraint when given" do
      expect(Winston::Constraint).to_not receive(:new)
      subject.add_constraint(constraint: constraint)
      expect(subject.constraints).to include(constraint)
    end
  end

  describe "#validate" do
    it "should return true when there aren't any constraints" do
      expect(subject.validate(:var, {})).to be(true)
    end

    it "should return false if one of the constraints returns invalid" do
      subject.add_constraint(:a) { true }
      subject.add_constraint(:a) { false }

      expect(subject.validate(:a, {a: 1})).to be(false)
    end

     it "should not attempt to validate ineligible constraints" do
      subject.add_constraint(:a) { true }
      subject.add_constraint(:b) { false }

      expect(subject.validate(:a, { a: 1 , b: 2 })).to be(true)
    end
  end

  describe "#solve" do
    let(:solver) { double("Solver") }
    before do
      subject.add_variable :a, value: 1
      subject.add_variable :b, domain: [1, 2]
    end

    it "should pass a collection of preset variables to the solver" do
      expect(solver).to receive(:search).with(a: 1)
      subject.solve(solver)
    end
  end
end
