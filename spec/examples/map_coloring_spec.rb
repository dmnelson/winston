require "winston"

describe "Map coloring example" do
  it "colors a simple map with three colors" do
    csp = Winston.define do
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

    solution = csp.solve

    expect(solution).to include(
      :western_australia,
      :northern_territory,
      :south_australia,
      :queensland,
      :new_south_wales,
      :victoria,
      :tasmania
    )
    expect(solution[:western_australia]).to_not eq(solution[:northern_territory])
    expect(solution[:western_australia]).to_not eq(solution[:south_australia])
    expect(solution[:northern_territory]).to_not eq(solution[:south_australia])
    expect(solution[:northern_territory]).to_not eq(solution[:queensland])
    expect(solution[:south_australia]).to_not eq(solution[:queensland])
    expect(solution[:south_australia]).to_not eq(solution[:new_south_wales])
    expect(solution[:south_australia]).to_not eq(solution[:victoria])
    expect(solution[:queensland]).to_not eq(solution[:new_south_wales])
    expect(solution[:new_south_wales]).to_not eq(solution[:victoria])
  end
end
