require "bigdecimal"

class CurrenciesController < ApplicationController
  DECIMAL_AMOUNT_PATTERN = /\A(?:0|[1-9]\d*)(?:\.\d+)?\z/

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
    return if raw_amount.nil?

    normalized_amount = raw_amount.to_s.strip
    return unless DECIMAL_AMOUNT_PATTERN.match?(normalized_amount)

    amount = BigDecimal(normalized_amount, exception: false)
    float_amount = amount&.to_f
    amount if amount&.positive? && float_amount&.finite? && float_amount.positive?
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
