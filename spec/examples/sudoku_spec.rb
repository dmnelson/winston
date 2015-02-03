require "winston"

describe "Sudoku Example" do
  let(:csp) { Winston::CSP.new }

  describe "Unique values for every row, column and quadrant" do
    before do
      domain = [1, 2, 3, 4, 5, 6, 7, 8, 9]

      # Adding variables
      1.upto(9).each do |x|
        1.upto(9).each do |j|
          csp.add_variable({ x: x, y: j }, domain: domain)
        end
      end

      variables = csp.variables.keys

      # add columns and rows constraints
      1.upto(9).each do |i|
        column = variables.select { |name| name[:x] == i }
        row = variables.select { |name| name[:y] == i }

        csp.add_constraint constraint: Winston::Constraints::AllDifferent.new(variables: row, allow_nil: true)
        csp.add_constraint constraint: Winston::Constraints::AllDifferent.new(variables: column, allow_nil: true)
      end

      # blocks
      variables.each_slice(3).group_by { |i| (i[0][:y] -1)  % 9 }.values.flatten.each_slice(9).each do |vars|
        csp.add_constraint constraint: Winston::Constraints::AllDifferent.new(variables: vars, allow_nil: true)
      end
    end

    it "should return a valid solution" do
      expect(csp.solve).to eq({
        {:x=>1, :y=>1}=>1,
        {:x=>1, :y=>2}=>2,
        {:x=>1, :y=>3}=>3,
        {:x=>1, :y=>4}=>4,
        {:x=>1, :y=>5}=>5,
        {:x=>1, :y=>6}=>6,
        {:x=>1, :y=>7}=>7,
        {:x=>1, :y=>8}=>8,
        {:x=>1, :y=>9}=>9,
        {:x=>2, :y=>1}=>4,
        {:x=>2, :y=>2}=>5,
        {:x=>2, :y=>3}=>6,
        {:x=>2, :y=>4}=>7,
        {:x=>2, :y=>5}=>8,
        {:x=>2, :y=>6}=>9,
        {:x=>2, :y=>7}=>1,
        {:x=>2, :y=>8}=>2,
        {:x=>2, :y=>9}=>3,
        {:x=>3, :y=>1}=>7,
        {:x=>3, :y=>2}=>8,
        {:x=>3, :y=>3}=>9,
        {:x=>3, :y=>4}=>1,
        {:x=>3, :y=>5}=>2,
        {:x=>3, :y=>6}=>3,
        {:x=>3, :y=>7}=>4,
        {:x=>3, :y=>8}=>5,
        {:x=>3, :y=>9}=>6,
        {:x=>4, :y=>1}=>2,
        {:x=>4, :y=>2}=>1,
        {:x=>4, :y=>3}=>4,
        {:x=>4, :y=>4}=>3,
        {:x=>4, :y=>5}=>6,
        {:x=>4, :y=>6}=>5,
        {:x=>4, :y=>7}=>8,
        {:x=>4, :y=>8}=>9,
        {:x=>4, :y=>9}=>7,
        {:x=>5, :y=>1}=>3,
        {:x=>5, :y=>2}=>6,
        {:x=>5, :y=>3}=>5,
        {:x=>5, :y=>4}=>8,
        {:x=>5, :y=>5}=>9,
        {:x=>5, :y=>6}=>7,
        {:x=>5, :y=>7}=>2,
        {:x=>5, :y=>8}=>1,
        {:x=>5, :y=>9}=>4,
        {:x=>6, :y=>1}=>8,
        {:x=>6, :y=>2}=>9,
        {:x=>6, :y=>3}=>7,
        {:x=>6, :y=>4}=>2,
        {:x=>6, :y=>5}=>1,
        {:x=>6, :y=>6}=>4,
        {:x=>6, :y=>7}=>3,
        {:x=>6, :y=>8}=>6,
        {:x=>6, :y=>9}=>5,
        {:x=>7, :y=>1}=>5,
        {:x=>7, :y=>2}=>3,
        {:x=>7, :y=>3}=>1,
        {:x=>7, :y=>4}=>6,
        {:x=>7, :y=>5}=>4,
        {:x=>7, :y=>6}=>2,
        {:x=>7, :y=>7}=>9,
        {:x=>7, :y=>8}=>7,
        {:x=>7, :y=>9}=>8,
        {:x=>8, :y=>1}=>6,
        {:x=>8, :y=>2}=>4,
        {:x=>8, :y=>3}=>2,
        {:x=>8, :y=>4}=>9,
        {:x=>8, :y=>5}=>7,
        {:x=>8, :y=>6}=>8,
        {:x=>8, :y=>7}=>5,
        {:x=>8, :y=>8}=>3,
        {:x=>8, :y=>9}=>1,
        {:x=>9, :y=>1}=>9,
        {:x=>9, :y=>2}=>7,
        {:x=>9, :y=>3}=>8,
        {:x=>9, :y=>4}=>5,
        {:x=>9, :y=>5}=>3,
        {:x=>9, :y=>6}=>1,
        {:x=>9, :y=>7}=>6,
        {:x=>9, :y=>8}=>4,
        {:x=>9, :y=>9}=>2
      })
    end
  end
end
