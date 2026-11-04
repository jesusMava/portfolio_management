# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

Allocation = Struct.new(:stock, :percentage, keyword_init: true)

class Stock
  attr_reader :symbol, :shares, :current_price

  def initialize(symbol:, shares: 0, current_price:)
    @symbol = symbol
    @shares = BigDecimal(shares.to_s)
    @current_price = BigDecimal(current_price.to_s)
  end

  def market_value
    @shares * @current_price
  end
end

class Portfolio
  attr_reader :stocks, :allocation

  def initialize(stocks:, allocation:)
    @stocks = Array(stocks)
    @allocation = Array(allocation).map do |entry|
      if entry.is_a?(Allocation)
        entry
      else
        Allocation.new(
          stock: Stock.new(
            symbol: entry[:stock][:symbol],
            shares: entry[:stock][:shares] || 0,
            current_price: entry[:stock][:current_price]
          ),
          percentage: entry[:percentage]
        )
      end
    end

    normalize_allocation!
  end

  def rebalance
    total_value = @stocks.sum(&:market_value)
    return { buys: [], sells: [] } if total_value.zero?

    target_by_symbol = {}
    @allocation.each do |entry|
      target_by_symbol[entry.stock.symbol] = total_value * BigDecimal(entry.percentage.to_s)
    end

    sells = []
    buys = []

    @stocks.each do |stock|
      target_value = target_by_symbol.fetch(stock.symbol, BigDecimal("0"))
      difference = target_value - stock.market_value

      if difference.negative?
        shares_to_sell = (difference.abs / stock.current_price).to_d
        sells << {
          stock: stock.symbol,
          shares: shares_to_sell,
          value: difference.abs
        }
      elsif difference.positive?
        shares_to_buy = (difference / stock.current_price).to_d
        buys << {
          stock: stock.symbol,
          shares: shares_to_buy,
          value: difference
        }
      end
    end

    @allocation.each do |entry|
      next if @stocks.any? { |stock| stock.symbol == entry.stock.symbol }

      desired_value = target_by_symbol[entry.stock.symbol]
      shares_to_buy = (desired_value / entry.stock.current_price).to_d
      buys << {
        stock: entry.stock.symbol,
        shares: shares_to_buy,
        value: desired_value
      }
    end

    { buys: buys, sells: sells }
  end

  private

  def normalize_allocation!
    return if @allocation.empty?

    total_percentage = @allocation.reduce(BigDecimal("0")) do |sum, entry|
      sum + BigDecimal(entry.percentage.to_s)
    end

    if total_percentage.zero?
      raise ArgumentError, "Allocation percentages cannot add up to zero."
    end

    if total_percentage != BigDecimal("1")
      @allocation.each do |entry|
        entry.percentage = BigDecimal(entry.percentage.to_s) / total_percentage
      end
    end
  end
end
