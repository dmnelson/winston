require "benchmark"
require "timeout"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "winston"

TIMEOUT_SECONDS = 10
RUNS = 5

def timed(label)
  seconds = nil
  status = :ok

  begin
    Timeout.timeout(TIMEOUT_SECONDS) do
      samples = []
      RUNS.times do
        samples << Benchmark.realtime { yield }
      end
      seconds = samples
    end
  rescue Timeout::Error
    status = :timeout
  end

  if status == :ok
    avg = seconds.sum / seconds.size
    min = seconds.min
    max = seconds.max
    puts format("%-28s %0.4fs (avg, %0.4f-%0.4f)", label, avg, min, max)
  else
    puts format("%-28s %s", label, "timeout (#{TIMEOUT_SECONDS}s)")
  end
end

def map_coloring_csp
  Winston.define do
    domain :colors, %i[red green blue]

    var :western_australia, domain: :colors
    var :northern_territory, domain: :colors
    var :south_australia, domain: :colors
    var :queensland, domain: :colors
    var :new_south_wales, domain: :colors
    var :victoria, domain: :colors
    var :tasmania, domain: :colors

    constraint(:western_australia, :northern_territory) { |wa, nt| wa != nt }
    constraint(:western_australia, :south_australia) { |wa, sa| wa != sa }
    constraint(:northern_territory, :south_australia) { |nt, sa| nt != sa }
    constraint(:northern_territory, :queensland) { |nt, q| nt != q }
    constraint(:south_australia, :queensland) { |sa, q| sa != q }
    constraint(:south_australia, :new_south_wales) { |sa, nsw| sa != nsw }
    constraint(:south_australia, :victoria) { |sa, v| sa != v }
    constraint(:queensland, :new_south_wales) { |q, nsw| q != nsw }
    constraint(:new_south_wales, :victoria) { |nsw, v| nsw != v }
  end
end

def dense_graph_coloring_csp(nodes: 18, colors: %i[red green blue], edge_probability: 0.6, seed: 42)
  # Dense constraint graph to compare propagation vs backtracking.
  random = Random.new(seed)
  csp = Winston::CSP.new
  nodes.times do |i|
    csp.add_variable(:"v#{i}", domain: colors)
  end

  edges = []
  (0...nodes).to_a.combination(2).each do |i, j|
    next unless random.rand < edge_probability
    edges << [i, j]
  end

  edges.each do |i, j|
    csp.add_constraint(:"v#{i}", :"v#{j}") { |a, b| a != b }
  end

  csp
end

def n_queens_csp(n)
  # AllDifferent-heavy problem to showcase GAC propagation.
  csp = Winston::CSP.new
  rows = (0...n).to_a
  rows.each { |row| csp.add_variable(:"row_#{row}", domain: rows) }
  csp.add_constraint constraint: Winston::Constraints::AllDifferent.new(variables: rows.map { |r| :"row_#{r}" })

  rows.combination(2).each do |i, j|
    csp.add_constraint(:"row_#{i}", :"row_#{j}") do |ci, cj|
      (ci - cj).abs != (i - j)
    end
  end
  csp
end

def random_binary_csp(vars: 50, domain: (1..5).to_a, edge_probability: 0.15, allowed_ratio: 0.5, seed: 42)
  # Random binary CSP near phase transition.
  random = Random.new(seed)
  csp = Winston::CSP.new
  vars.times { |i| csp.add_variable(:"x#{i}", domain: domain) }

  allowed_pairs = {}
  domain.each do |a|
    domain.each do |b|
      allowed_pairs[[a, b]] = random.rand < allowed_ratio
    end
  end

  (0...vars).to_a.combination(2).each do |i, j|
    next unless random.rand < edge_probability
    csp.add_constraint(:"x#{i}", :"x#{j}") do |x, y|
      allowed_pairs[[x, y]]
    end
  end

  csp
end

def hard_binary_csp
  # Larger binary CSP to test search vs propagation overhead.
  random_binary_csp(vars: 80, domain: (1..6).to_a, edge_probability: 0.35, allowed_ratio: 0.35, seed: 1337)
end

def sudoku_csp
  # Medium puzzle for balanced comparison.
  puzzle = [
    [8, 0, 0, 1, 0, 4, 0, 9, 0],
    [9, 6, 0, 0, 2, 7, 1, 0, 8],
    [3, 4, 1, 6, 0, 0, 7, 5, 0],
    [5, 0, 3, 4, 0, 8, 0, 7, 1],
    [4, 7, 0, 0, 1, 3, 6, 0, 9],
    [6, 1, 8, 9, 0, 2, 0, 3, 0],
    [0, 0, 0, 2, 3, 5, 0, 1, 4],
    [0, 0, 4, 7, 0, 6, 8, 0, 3],
    [0, 0, 9, 8, 4, 1, 5, 0, 7]
  ]

  csp = Winston::CSP.new
  digits = (1..9).to_a
  (0...9).each do |r|
    (0...9).each do |c|
      value = puzzle[r][c]
      name = :"r#{r}c#{c}"
      if value == 0
        csp.add_variable(name, domain: digits)
      else
        csp.add_variable(name, value: value)
      end
    end
  end

  rows = (0...9).map { |r| (0...9).map { |c| :"r#{r}c#{c}" } }
  cols = (0...9).map { |c| (0...9).map { |r| :"r#{r}c#{c}" } }
  boxes = []
  [0, 3, 6].each do |br|
    [0, 3, 6].each do |bc|
      box = []
      (0...3).each do |r|
        (0...3).each do |c|
          box << :"r#{br + r}c#{bc + c}"
        end
      end
      boxes << box
    end
  end

  (rows + cols + boxes).each do |group|
    group.combination(2).each do |a, b|
      csp.add_constraint(a, b) { |x, y| x != y }
    end
  end

  csp
end

def sudoku_hard_csp
  # Harder puzzle with more branching.
  puzzle = [
    [0, 0, 0, 2, 6, 0, 7, 0, 1],
    [6, 8, 0, 0, 7, 0, 0, 9, 0],
    [1, 9, 0, 0, 0, 4, 5, 0, 0],
    [8, 2, 0, 1, 0, 0, 0, 4, 0],
    [0, 0, 4, 6, 0, 2, 9, 0, 0],
    [0, 5, 0, 0, 0, 3, 0, 2, 8],
    [0, 0, 9, 3, 0, 0, 0, 7, 4],
    [0, 4, 0, 0, 5, 0, 0, 3, 6],
    [7, 0, 3, 0, 1, 8, 0, 0, 0]
  ]

  csp = Winston::CSP.new
  digits = (1..9).to_a
  (0...9).each do |r|
    (0...9).each do |c|
      value = puzzle[r][c]
      name = :"r#{r}c#{c}"
      if value == 0
        csp.add_variable(name, domain: digits)
      else
        csp.add_variable(name, value: value)
      end
    end
  end

  rows = (0...9).map { |r| (0...9).map { |c| :"r#{r}c#{c}" } }
  cols = (0...9).map { |c| (0...9).map { |r| :"r#{r}c#{c}" } }
  boxes = []
  [0, 3, 6].each do |br|
    [0, 3, 6].each do |bc|
      box = []
      (0...3).each do |r|
        (0...3).each do |c|
          box << :"r#{br + r}c#{bc + c}"
        end
      end
      boxes << box
    end
  end

  (rows + cols + boxes).each do |group|
    group.combination(2).each do |a, b|
      csp.add_constraint(a, b) { |x, y| x != y }
    end
  end

  csp
end

def sudoku_very_hard_csp
  # Very hard puzzle to stress propagation.
  puzzle = [
    [0, 0, 0, 0, 0, 0, 0, 0, 1],
    [0, 0, 0, 0, 2, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 9, 0, 0, 0],
    [0, 0, 0, 5, 0, 0, 0, 4, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 6, 0, 0, 0, 1, 0, 0, 0],
    [0, 0, 0, 9, 0, 0, 8, 0, 0],
    [0, 0, 0, 0, 7, 0, 0, 0, 0],
    [7, 0, 0, 0, 0, 0, 0, 0, 0]
  ]

  csp = Winston::CSP.new
  digits = (1..9).to_a
  (0...9).each do |r|
    (0...9).each do |c|
      value = puzzle[r][c]
      name = :"r#{r}c#{c}"
      if value == 0
        csp.add_variable(name, domain: digits)
      else
        csp.add_variable(name, value: value)
      end
    end
  end

  rows = (0...9).map { |r| (0...9).map { |c| :"r#{r}c#{c}" } }
  cols = (0...9).map { |c| (0...9).map { |r| :"r#{r}c#{c}" } }
  boxes = []
  [0, 3, 6].each do |br|
    [0, 3, 6].each do |bc|
      box = []
      (0...3).each do |r|
        (0...3).each do |c|
          box << :"r#{br + r}c#{bc + c}"
        end
      end
      boxes << box
    end
  end

  (rows + cols + boxes).each do |group|
    group.combination(2).each do |a, b|
      csp.add_constraint(a, b) { |x, y| x != y }
    end
  end

  csp
end

def run_case(name, csp)
  puts "\n#{name}"
  timed("Backtrack") { csp.solve(:backtrack) }
  timed("MAC (default)") { csp.solve(:mac) }
  timed("MAC (mrv)") { csp.solve(:mac, variable_strategy: :mrv) }
  timed("Min-Conflicts") do
    csp.solve(:min_conflicts, max_steps: 10_000, random: Random.new(1))
  end
end

run_case("Map coloring (Australia)", map_coloring_csp)
run_case(
  "Dense graph coloring (18)",
  dense_graph_coloring_csp(nodes: 18, edge_probability: 0.7, seed: 42)
)
run_case(
  "Dense graph coloring (30)",
  dense_graph_coloring_csp(nodes: 30, edge_probability: 0.8, seed: 42)
)
run_case(
  "Random binary CSP (50)",
  random_binary_csp(vars: 50, edge_probability: 0.15, allowed_ratio: 0.5, seed: 42)
)
run_case(
  "Hard binary CSP (80)",
  hard_binary_csp
)
run_case("N-Queens (8)", n_queens_csp(8))
run_case("Sudoku (medium)", sudoku_csp)
run_case("Sudoku (hard)", sudoku_hard_csp)
run_case("Sudoku (very hard)", sudoku_very_hard_csp)
