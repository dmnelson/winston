# Winston

[Constraint Satisfaction Problem](http://en.wikipedia.org/wiki/Constraint_satisfaction_problem) (CSP) implementation for Ruby. 
It provides a useful way to solve problems like resource allocation or planning though a set of constraints.

The most common example of usage for CSPs is probably the game [Sudoku](http://en.wikipedia.org/wiki/Sudoku).

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
  assignmets.values.uniq.size == assignments.keys.size # checks if every value is unique
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

Check the folder `specs/examples` for more usage examples.

## TODOs / Nice-to-haves

- Create a DSL for setting up the problem
- Currently only algorithm to solve the CSP is Backtracking, implement other like Local search, Constraint propagation, ...
- Implement heuristics to improve search time (least constraining value, minimum remaining values,...)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
