require "winston"

describe Winston::Constraints::NotInList do
  subject { described_class.new(list: [ 4, 5, 6 ]) }

  describe "#validate" do
    it "should return 'true' none of the values are on the list" do
      expect(subject.validate(a: 1, b: 2, c: 3, d: 3)).to be(true)
    end

    it "should return 'false' when any of the values are on the list" do
      expect(subject.validate(a: 1, b: 2, c: 2, d: 4)).to be(false)
    end

    it "should return 'false' when all the values are on the list" do
      expect(subject.validate(a: 4, b: 6, c: 5, d: 4)).to be(false)
    end

    context "for specific variables" do
      subject { described_class.new(variables: [:a, :b, :c], list: [ 4, 5, 6 ]) }

      it "should return 'true' when none of the values are on the list" do
        expect(subject.validate(a: 1, b: 2, c: 3, d: 6)).to be(true)
      end

      it "should return 'false' when any of the values are on the list" do
        expect(subject.validate(a: 1, b: 2, c: 5, d: 3)).to be(false)
      end

      it "should return 'false' when all the values are on the list" do
        expect(subject.validate(a: 4, b: 6, c: 5, d: 3)).to be(false)
      end
    end
  end
end
