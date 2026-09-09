require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  test "current_price delegates the slug to the CoinMarketCap client" do
    currency = Currency.new(slug: "bitcoin")
    received_slug = nil
    client = Object.new
    client.define_singleton_method(:price_for) do |slug:|
      received_slug = slug
      42_000.0
    end

    assert_equal 42_000.0, currency.current_price(client: client)
    assert_equal "bitcoin", received_slug
  end

  test "calculate_value multiplies the current price by the supplied amount" do
    currency = Currency.new(slug: "bitcoin")
    currency.define_singleton_method(:current_price) { 12_500.0 }

    assert_equal 31_250.0, currency.calculate_value(2.5)
  end
end
