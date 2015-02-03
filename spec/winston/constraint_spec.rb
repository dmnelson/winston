require "winston"

describe Winston::Constraint do

  let(:variables) { nil }
  let(:predicate) { nil }
  let(:allow_nil) { false }
  subject { described_class.new(variables: variables, predicate: predicate, allow_nil: allow_nil) }

  describe "#elegible_for?" do
    context "global" do
      it "should be elegible for everything" do
        expect(subject.elegible_for?(:a, {})).to be(true)
        expect(subject.elegible_for?(:b, { a: 1 })).to be(true)
      end
    end

    context "for specific variable" do
      let(:variables) { [:a] }

      it "should return true when that variable is changed" do
        expect(subject.elegible_for?(:a, { a: nil })).to be(true)
      end

      it "should return false when that variable isn't the one changed" do
        expect(subject.elegible_for?(:b, { a: 1, b: 2 })).to be(false)
      end

      it "should return false when that variable is changed but doesn't have a value" do
        expect(subject.elegible_for?(:a, { b: 2 })).to be(false)
      end
    end

    context "for multiple variables" do
      let(:variables) { [:a, :b] }

      it "should return true when one of those variables is changed" do
        expect(subject.elegible_for?(:a, { a: 1, b: nil })).to be(true)
      end

      it "should return false when one of those variables isn't the one changed" do
        expect(subject.elegible_for?(:c, { a: 1, b: 2 })).to be(false)
      end

      it "should return false when one of those variables is changed but doesn't have a value for every one of them" do
        expect(subject.elegible_for?(:b, { b: 2 })).to be(false)
      end

      it "should return false when one of those variables is changed but doesn't have a value for every one of them" do
        expect(subject.elegible_for?(:a, { b: 2 })).to be(false)
      end
    end

    context "allowing nil" do
      let(:allow_nil) { true }

      context "for specific variable" do
        let(:variables) { [:a] }

        it "should return true when that variable is changed" do
          expect(subject.elegible_for?(:a, { a: nil })).to be(true)
        end

        it "should return false when that variable isn't the one changed" do
          expect(subject.elegible_for?(:b, { a: 1, b: 2 })).to be(false)
        end

        it "should return true when that variable is changed but doesn't have a value" do
          expect(subject.elegible_for?(:a, { b: 2 })).to be(true)
        end
      end

      context "for multiple variables" do
        let(:variables) { [:a, :b] }

        it "should return true when one of those variables is changed" do
          expect(subject.elegible_for?(:a, { a: 1, b: nil })).to be(true)
        end

        it "should return false when one of those variables isn't the one changed" do
          expect(subject.elegible_for?(:c, { a: 1, b: 2 })).to be(false)
        end

        it "should return true when one of those variables is changed but doesn't have a value for every one of them" do
          expect(subject.elegible_for?(:b, { b: 2 })).to be(true)
        end

        it "should return true when one of those variables is changed but doesn't have a value for every one of them" do
          expect(subject.elegible_for?(:a, { b: 2 })).to be(true)
        end

        it "should return true when one of those variables is changed but doesn't have a value for any of them" do
          expect(subject.elegible_for?(:a, {})).to be(true)
        end
      end
    end
  end

  describe "#validate" do
    context "no predicate is given" do
      it "should be considerated invalid" do
        expect(subject.validate(a: 1)).to be(false)
      end
    end

    context "when a predicate is given" do
      context "on a global constraint" do
        let(:predicate) do
          proc { |assignments| assignments[:a] > assignments[:b] }
        end

        it "should evaluate that predicate" do
          expect(subject.validate(a: 2, b: 1)).to be(true)
          expect(subject.validate(a: 1, b: 2)).to be(false)
        end
      end

      context "on an unary constraint" do
        let(:variables) { [:a] }
        let(:predicate) do
          proc { |a, assignments| a % 2 == 0 && !assignments.reject { |k,_| k == :a }.values.include?(a) }
        end

        it "should evaluate that predicate" do
          expect(subject.validate(a: 2, b: 1)).to be(true)
          expect(subject.validate(a: 1, b: 2)).to be(false)
          expect(subject.validate(a: 2, b: 2)).to be(false)
        end
      end

      context "on a n-ary constraint" do
        let(:variables) { [:a, :b, :c] }
        let(:predicate) do
          proc { |a, b, c, assignments| a > b && b > c }
        end

        it "should evaluate that predicate" do
          expect(subject.validate(a: 2, b: 1, c: 0)).to be(true)
          expect(subject.validate(a: 1, b: 2, c: 1)).to be(false)
        end
      end
    end
  end
end
