require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  test "current_price uses the configured CoinMarketCap API key" do
    currency = Currency.new(slug: "bitcoin")
    response = Struct.new(:body).new(
      { data: { "1" => { quote: { USD: { price: 42_000.0 } } } } }.to_json
    )
    captured_headers = nil

    ENV.stub(:fetch, "configured-key") do
      HTTParty.stub(:get, ->(_url, options) {
        captured_headers = options[:headers]
        response
      }) do
        assert_equal 42_000.0, currency.current_price
      end
    end

    assert_equal "configured-key", captured_headers["X-CMC_PRO_API_KEY"]
  end

  test "current_price fails clearly when the API key is missing" do
    currency = Currency.new(slug: "bitcoin")

    ENV.stub(:fetch, ->(_key) { raise KeyError, "COINMARKETCAP_API_KEY is not configured" }) do
      error = assert_raises(KeyError) { currency.current_price }
      assert_match "COINMARKETCAP_API_KEY is not configured", error.message
    end
  end
end
