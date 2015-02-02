require "winston"

describe Winston::Domain do
  let(:csp) { double("CSP") }
  let(:variable) { :var }

  subject { described_class.new(csp, variable, values) }

  describe "#values" do
    context "when given 'values' is a collection" do
      let(:values) { [1, 2, 3] }

      it "should return that collection" do
        expect(subject.values).to eq([1, 2, 3])
      end
    end

    context "when given 'values' is a proc" do
      let(:values) do
        i = 0
        proc do |given_variable, given_csp|
          expect(given_variable).to eq(variable)
          expect(given_csp).to eq(csp)

          [i += 1]
        end
      end

      it "should return the result of the evatualtion of that proc" do
        expect(subject.values).to eq([1])
        expect(subject.values).to eq([2])
      end
    end
  end
end
