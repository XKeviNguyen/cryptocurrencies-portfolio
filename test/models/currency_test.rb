require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  API_KEY_ENV = Currency::COINMARKETCAP_API_KEY_ENV

  teardown do
    restore_api_key
  end

  test "current_price uses the configured CoinMarketCap API key" do
    currency = Currency.new(slug: "bitcoin")
    response = Struct.new(:body).new(
      { data: { "1" => { quote: { USD: { price: 42_000.0 } } } } }.to_json
    )
    captured_headers = nil

    remember_api_key
    ENV[API_KEY_ENV] = "configured-key"

    HTTParty.stub(:get, ->(_url, options) {
      captured_headers = options[:headers]
      response
    }) do
      assert_equal 42_000.0, currency.current_price
    end

    assert_equal "configured-key", captured_headers["X-CMC_PRO_API_KEY"]
  end

  test "current_price fails clearly when the API key is missing" do
    currency = Currency.new(slug: "bitcoin")

    remember_api_key
    ENV.delete(API_KEY_ENV)

    error = assert_raises(KeyError) { currency.current_price }
    assert_match "COINMARKETCAP_API_KEY is not configured", error.message
  end

  private

  def remember_api_key
    @original_api_key_present = ENV.key?(API_KEY_ENV)
    @original_api_key = ENV[API_KEY_ENV]
  end

  def restore_api_key
    return unless defined?(@original_api_key_present)

    if @original_api_key_present
      ENV[API_KEY_ENV] = @original_api_key
    else
      ENV.delete(API_KEY_ENV)
    end
  end
end
