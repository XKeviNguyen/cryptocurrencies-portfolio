require "bigdecimal"

class CurrenciesController < ApplicationController
  def index
  end

  def search
    @currencies = Currency.where('LOWER(name) LIKE?', "%#{params[:search].downcase}%")
    render json: { currencies: @currencies }
  end

  def calculate
    amount = parsed_amount
    return render_invalid_amount unless amount

    current_price = currency.current_price

    render json: {
      currency: currency,
      current_price: current_price,
      amount: params[:amount],
      value: currency.calculate_value(amount, price: current_price)
    }
  rescue CoinMarketCapClient::Error, KeyError
    render json: {
      error: {
        code: "market_data_unavailable",
        message: "Market price is temporarily unavailable"
      }
    }, status: :service_unavailable
  end

  private

  def parsed_amount
    raw_amount = params[:amount]
    return if raw_amount.nil? || raw_amount.to_s.strip.empty?

    amount = BigDecimal(raw_amount.to_s, exception: false)
    amount if amount&.finite? && amount.positive?
  end

  def render_invalid_amount
    render json: {
      error: {
        code: "invalid_amount",
        message: "Amount must be a positive number"
      }
    }, status: :unprocessable_entity
  end

  def currency
    @currency ||= Currency.find(params[:id])
  end
end
