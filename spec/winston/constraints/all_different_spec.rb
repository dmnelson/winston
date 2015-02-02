require "winston"

describe Winston::Constraints::AllDifferent do
  subject { described_class.new }

  describe "#elegible_for?" do
    it "should be elegible for everything" do
      expect(subject.elegible_for?(:a, {})).to be(true)
      expect(subject.elegible_for?(:b, { a: 1 })).to be(true)
    end
  end

  describe "#validate" do
    it "should return 'true' when all values are unique" do
      expect(subject.validate(a: 1, b: 2, c: 3, d: 4)).to be(true)
    end

    it "should return 'false' when not all values are unique" do
      expect(subject.validate(a: 1, b: 2, c: 2, d: 4)).to be(false)
    end
  end
end
