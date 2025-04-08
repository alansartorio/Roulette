local MyMath = require("my-math")

local RouletteTableData = require("roulette-table-data")

local roulette = RouletteTableData.new()

roulette:bid_number(10, "2")
assert(roulette:get_return("3") == 0)
assert(roulette:get_return("2") == 360)
roulette:reset_bid()

roulette:bid_number(1, "2")
roulette:bid_even(1)
roulette:bid_column(1, 1)
roulette:bid_third(1, 1)
roulette:bid_row(1, 2)
assert(MyMath.round(roulette:get_return("0")) == 0)
assert(MyMath.round(roulette:get_return("1")) == 15)
assert(MyMath.round(roulette:get_return("2")) == 36 + 2 + 12 + 3 + 3)
roulette:reset_bid()
