# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/portfolio"

class PortfolioTest < Minitest::Test
  def test_rebalance_sells_when_current_stock_is_overweight
    meta = Stock.new(symbol: "META", shares: 20, current_price: 150)
    aapl = Stock.new(symbol: "AAPL", shares: 10, current_price: 120)

    portfolio = Portfolio.new(
      stocks: [meta, aapl],
      allocation: [
        Allocation.new(stock: meta, percentage: 0.4),
        Allocation.new(stock: aapl, percentage: 0.6)
      ]
    )

    result = portfolio.rebalance

    sells = result[:sells]
    assert_equal 1, sells.length
    assert_equal "META", sells.first[:stock]
    assert_operator sells.first[:shares].to_f, :>, 0.0
    assert_operator sells.first[:value].to_f, :>, 0.0
    assert_operator result[:buys].length, :>=, 0
  end

  def test_rebalance_buys_when_current_stock_is_underweight
    meta = Stock.new(symbol: "META", shares: 5, current_price: 180)
    aapl = Stock.new(symbol: "AAPL", shares: 20, current_price: 90)

    portfolio = Portfolio.new(
      stocks: [meta, aapl],
      allocation: [
        Allocation.new(stock: meta, percentage: 0.4),
        Allocation.new(stock: aapl, percentage: 0.6)
      ]
    )

    result = portfolio.rebalance

    buys = result[:buys]
    assert_equal 1, buys.length
    assert_equal "META", buys.first[:stock]
    assert_operator buys.first[:shares].to_f, :>, 0.0
    assert_operator buys.first[:value].to_f, :>, 0.0
    assert_operator result[:sells].length, :>=, 0
  end

  def test_rebalance_accepts_percentage_totals_that_do_not_sum_to_100
    meta = Stock.new(symbol: "META", shares: 10, current_price: 100)
    aapl = Stock.new(symbol: "AAPL", shares: 10, current_price: 100)

    portfolio = Portfolio.new(
      stocks: [meta, aapl],
      allocation: [
        Allocation.new(stock: meta, percentage: 0.25),
        Allocation.new(stock: aapl, percentage: 0.35)
      ]
    )

    result = portfolio.rebalance

    assert_equal 2, result[:sells].length + result[:buys].length
  end
end
