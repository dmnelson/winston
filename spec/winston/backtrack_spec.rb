require "winston"

describe Winston::Backtrack do
  let(:csp) { Winston::CSP.new }
  subject { described_class.new(csp) }

  describe "#search" do
    context "simple assigment" do
      before do
        csp.add_variable :a, domain: [1, 2, 3, 4]
        csp.add_variable :b, domain: [1, 2, 3, 4]
        csp.add_variable :c, domain: [1, 2, 3, 4]
      end

      it "should assign variables to the first acceptable value" do
        expect(subject.search).to eq(a: 1, b: 1, c: 1)
      end

      it "should assign variables to the first acceptable value respecting variables that already have a value" do
        expect(subject.search(b: 3)).to eq(a: 1, b: 3, c: 1)
      end

      context "with constraints" do
        before do
          csp.add_constraint(:a, :b) { |a,b| a > b }
          csp.add_constraint(:b, :c) { |b,c| b > c }
        end

        it "should assign variables to the first acceptable value" do
          expect(subject.search).to eq(a: 3, b: 2, c: 1)
        end

        it "should assign variables to the first acceptable value" do
          expect(subject.search(b: 3)).to eq(a: 4, b: 3, c: 1)
        end

        it "should return false when it cannot fufill the constraints" do
          expect(subject.search(c: 3)).to be(false)
        end

         it "should return false when it cannot fufill the constraints" do
           csp.add_constraint(:a, :c) { |a,c| a == c * 10 }
          expect(subject.search).to be(false)
        end
      end
    end
  end
end
