# Winston

[Constraint Satisfaction Problem](http://en.wikipedia.org/wiki/Constraint_satisfaction_problem) (CSP) implementation for Ruby. 
It provides a useful way to solve problems like resource allocation or planning though a set of constraints.

The most common example of usage for CSPs is probably the game [Sudoku](http://en.wikipedia.org/wiki/Sudoku).

[![Gem Version](https://badge.fury.io/rb/winston.svg)](http://badge.fury.io/rb/winston) [![Build Status](https://travis-ci.org/dmnelson/winston.svg)](https://travis-ci.org/dmnelson/winston) [![Code Climate](https://codeclimate.com/github/dmnelson/winston/badges/gpa.svg)](https://codeclimate.com/github/dmnelson/winston)

## Installation

Add this line to your application's Gemfile:

    gem 'winston'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install winston

## Usage

The problem consists of three sets of information: Domain, Variables and Constraints. It will try to determine a value
from the given domain for each variable that will attend all the constraints. 

```ruby
require 'winston'

csp = Winston::CSP.new

csp.add_variable :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
csp.add_variable :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]
csp.add_variable :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9]

csp.add_constraint(:a, :c) { |a, c| a == c * 2 } # 'a' has to be double of 'c'.
csp.add_constraint(:a, :b) { |a, b| a > b } # 'a' has to be greater than 'b'.
csp.add_constraint(:b, :c) { |b, c| b > c } # 'b' has to be greater than 'c'.
csp.add_constraint(:b) { |b| b % 2 == 0 } # 'b' has to be even.

csp.solve 
= { a: 6, b: 4, c: 3 }
```

### Solvers and heuristics

The default solver is backtracking, and you can configure it with heuristics to speed up search on harder problems.

```ruby
solver = Winston::Backtrack.new(
  csp,
  variable_strategy: :mrv,
  value_strategy: :lcv,
  forward_checking: true
)

csp.solve(solver)
```

You can also pass your own strategies as lambdas:

```ruby
custom_var = ->(vars, assignments, csp) { vars.first }
custom_val = ->(values, var, assignments, csp) { values.reverse }

solver = Winston::Backtrack.new(
  csp,
  variable_strategy: custom_var,
  value_strategy: custom_val
)
```

Built-in heuristic helpers are also available:

```ruby
solver = Winston::Backtrack.new(
  csp,
  variable_strategy: Winston::Heuristics.mrv,
  value_strategy: Winston::Heuristics.lcv,
  forward_checking: Winston::Heuristics.forward_checking
)
```

### DSL

You can build problems using a small DSL:

```ruby
csp = Winston.define do
  domain :digits, (1..9).to_a

  var :a, domain: :digits
  var :b, domain: :digits
  var :c, domain: :digits

  constraint(:a, :c) { |a, c| a == c * 2 }
  constraint(:a, :b) { |a, b| a > b }
  constraint(:b, :c) { |b, c| b > c }
  constraint(:b) { |b| b.even? }
end

csp.solve
```

#### DSL Reference

`Winston.define { ... }` builds and returns a `Winston::CSP`.

DSL methods:
- `domain :name, values` registers a named domain.
- `var :name, domain: <values or :name>, value: <preset>, &block` adds a variable.
- `constraint(*vars, allow_nil: false) { |*values, assignments| ... }` adds a custom constraint.
- `use_constraint :name, *vars, allow_nil: false, **options` adds a named constraint.

Notes:
- Domains are static. Use constraints for dynamic behavior.
- `value:` presets a variable and is validated before search starts.
- `allow_nil: true` lets a constraint run even if some variables are unset.

#### Named Domains

Named domains reduce repetition and keep variable declarations clean:

```ruby
Winston.define do
  domain :digits, (1..9).to_a
  var :a, domain: :digits
  var :b, domain: :digits
end
```

#### Named Constraints

Built-in named constraints:
- `:all_different`
- `:not_in_list`

```ruby
Winston.define do
  var :a, domain: [1, 2]
  var :b, domain: [1, 2]
  use_constraint :all_different, :a, :b
end
```

Register custom constraints:

```ruby
Winston.register_constraint(:all_twos) do |variables, allow_nil, **_options|
  Class.new(Winston::Constraint) do
    def validate(assignments)
      values = values_at(assignments)
      values.all? { |v| v == 2 }
    end
  end.new(variables: variables, allow_nil: allow_nil)
end
```

Use them in the DSL:

```ruby
Winston.define do
  var :a, domain: [1, 2]
  var :b, domain: [1, 2]
  use_constraint :all_twos, :a, :b
end
```

### Variables and Domain

It's possible to preset values for variables, and in that case the problem would not try to determine values for
it, but it will take those values into account for validating the constraints.

```ruby
csp.add_variable "my_var", value: "predefined value"
```

And it's also possible to set the domain as `Proc` so it'd be evaluated on-demand.

```ruby
csp.add_variable("other_var") { |var_name, csp| [:a, :b, :c ] } 
# same as 
csp.add_variable("other_var", domain: proc { |var_name, csp| [:a, :b, :c ] })
```

### Constraints

Constraints can be set for specific variables and would be evaluated only when all those variables are set and one
of them has changed; Or globals, in which case, they'd evaluated for every assignment.

```ruby
csp.add_constraint(:a) { |a| a > 0 } # positive value

# the last argument passed to the block is always a map of assignments, in other words, the current
# state of the solution

csp.add_constraint(:a) do |a, assignments| 
  !assignments.reject { |name, value| name == :a }.values.include?(a) #checks if the value is not present on other variables
end 

# a global constraint is evaluated for every assignment and the only argument it receives is a
# hash with all current assignments

csp.add_constraint do |assignments|
  assignments.values.uniq.size == assignments.keys.size # checks if every value is unique
end
```

Constraint can be also set as their own objects, that's great for reusability.

```ruby
csp.add_constraint constraint: MyConstraint.new(...)
# ...
csp.add_constraint constraint: Winston::Constraints::AllDifferent.new # built-in constraint, checks if all values are different from each other
```

### Problems without solution

```ruby
require 'winston'

csp = Winston::CSP.new

csp.add_variable :a, domain: [1, 2]
csp.add_variable :b, domain: [1, 2]
csp.add_variable :c, domain: [1, 2]

csp.add_constraint constraint: Winston::Constraints::AllDifferent.new

csp.solve 
= false
```

**IMPORTANT NOTE: Depending on the number of variables and the size of the domain it can take a long time to test all different possibilities.
In that case it'll be recomendable to use of ways to reduce the number of iterations, for example, removing an item from a shared domain
when it is tested ( A `queue` type of structure, that would `pop` the value on the `each` block).**

### More examples

Check the folder `spec/examples` for more usage examples.
The `spec/examples/map_coloring_spec.rb` example is a good starting point for small graph problems.

## TODOs / Nice-to-haves

- Currently only algorithm to solve the CSP is Backtracking, implement other like Local search, Constraint propagation, ...
- Add constraint propagation and other inference techniques

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
