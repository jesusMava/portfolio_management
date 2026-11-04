# Portfolio rebalance demo

This project is a small Ruby-only portfolio module that rebalances a set of holdings against a target allocation.

## Thinking process and assumptions

The main idea was to keep the calculation simple and readable:

1. Calculate the total market value of the current portfolio.
2. Translate each target percentage into a target monetary value.
3. Traverse both the stocks you currently hold and the allocation entries.
4. Sell what is above target.
5. Buy what is below target, including missing symbols from the desired allocation.

Specific assumptions in this solution:

- Money and percentages use `BigDecimal` instead of `Float` to avoid rounding drift.
- Fractional shares are allowed. Example: if the model says we need to buy 1.37 shares, that is accepted as a valid rebalance result.
- If the allocation does not sum to 100%, the code normalizes the percentages so that they still behave as relative weights. For example, 25% + 35% = 60% becomes 41.67% and 58.33%.
- "Current Price" is treated as the last available market price for each stock.
- We do not try to model tax, fees, slippage, or transaction costs in this initial version.

## How the algorithm works

The rebalance logic checks two sources of truth:

- the portfolio's current positions
- the desired allocation

When we iterate over current holdings, we compute:

```ruby
current_value = stock.market_value
target_value = total_value * percentage
```

Then:

- if `current_value > target_value`, we add a sell operation for the difference
- if `current_value < target_value`, we add a buy operation for the difference

When we iterate over the allocation entries, we also check whether that symbol is missing from the current portfolio. If it is missing, we create a buy for the target value.

This matches the review comment: we traverse both the actions you own and the desired distribution so that the code sells the excess and buys the missing portion.

## Worked example

Suppose the portfolio has two stocks:

```ruby
meta = Stock.new(symbol: "META", shares: 20, current_price: 150)
aapl = Stock.new(symbol: "AAPL", shares: 10, current_price: 120)
```

Total portfolio value:

- META: 20 * 150 = 3,000
- AAPL: 10 * 120 = 1,200
- Total = 4,200

Target allocation:

- META: 40%
- AAPL: 60%

Target values:

- META target = 4,200 * 0.4 = 1,680
- AAPL target = 4,200 * 0.6 = 2,520

Current values:

- META current = 3,000 -> above target by 1,320
- AAPL current = 1,200 -> below target by 1,320

Rebalance result:

- sell META worth 1,320
- buy AAPL worth 1,320

This is exactly the kind of operation the method returns in `:sells` and `:buys`.

## Example with percentages that do not add to 100%

If the allocation is:

```ruby
[
  Allocation.new(stock: meta, percentage: 0.25),
  Allocation.new(stock: aapl, percentage: 0.35)
]
```

The sum is 0.60, so the code normalizes both values to relative weights:

- META = 0.25 / 0.60 = 0.4167
- AAPL = 0.35 / 0.60 = 0.5833

That means the target weights become 41.67% and 58.33% instead of being treated as invalid or rejected.

## Ruby usage

```ruby
require_relative "lib/portfolio"

meta = Stock.new(symbol: "META", shares: 20, current_price: 150)
aapl = Stock.new(symbol: "AAPL", shares: 10, current_price: 120)

portfolio = Portfolio.new(
  stocks: [meta, aapl],
  allocation: [
    Allocation.new(stock: meta, percentage: 0.4),
    Allocation.new(stock: aapl, percentage: 0.6)
  ]
)

p portfolio.rebalance
```

The output is a hash structured like this:

```ruby
{
  buys: [
    { stock: "AAPL", shares: 11.0, value: 1320 }
  ],
  sells: [
    { stock: "META", shares: 8.8, value: 1320 }
  ]
}
```

## Tests

This project contains targeted tests for:

- selling excess when one stock is overweighted
- buying a shortfall when one stock is underweighted
- handling allocations whose percentages do not sum to 100%

Run them with:

```bash
ruby -Ilib:test test/portfolio_test.rb
```
