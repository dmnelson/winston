require "winston"

describe Winston::Constraints::AllDifferent do
  subject { described_class.new }

  describe "#validate" do
    it "should return 'true' when all values are unique" do
      expect(subject.validate(a: 1, b: 2, c: 3, d: 4)).to be(true)
    end

    it "should return 'false' when not all values are unique" do
      expect(subject.validate(a: 1, b: 2, c: 2, d: 4)).to be(false)
    end

    context "for specific variables" do
      subject { described_class.new(variables: [:a, :b, :c]) }

      it "should return 'true' when all values are unique" do
        expect(subject.validate(a: 1, b: 2, c: 3, d: 3)).to be(true)
      end

      it "should return 'false' when not all values are unique" do
        expect(subject.validate(a: 1, b: 2, c: 2, d: 4)).to be(false)
      end
    end
  end
end
