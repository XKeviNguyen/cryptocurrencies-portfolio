require 'test_helper'

class CoinMarketCapClientTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body)

  test "price_for returns the USD price and applies bounded request options" do
    captured_url = nil
    captured_options = nil
    http_client = Object.new
    http_client.define_singleton_method(:get) do |url, options|
      captured_url = url
      captured_options = options
      Response.new(
        200,
        { data: { "1" => { quote: { USD: { price: 42_000.0 } } } } }.to_json
      )
    end

    client = CoinMarketCapClient.new(api_key: "configured-key", http_client: http_client)

    assert_equal 42_000.0, client.price_for(slug: "bitcoin")
    assert_equal CoinMarketCapClient::ENDPOINT, captured_url
    assert_equal({ slug: "bitcoin" }, captured_options[:query])
    assert_equal "configured-key", captured_options[:headers]["X-CMC_PRO_API_KEY"]
    assert_equal CoinMarketCapClient::REQUEST_TIMEOUT_SECONDS, captured_options[:timeout]
  end

  test "initialization fails clearly when the API key is missing" do
    error = assert_raises(KeyError) do
      CoinMarketCapClient.new(api_key: nil, http_client: Object.new)
    end

    assert_match "COINMARKETCAP_API_KEY is not configured", error.message
  end

  test "price_for rejects blank slugs before making a request" do
    client = CoinMarketCapClient.new(api_key: "configured-key", http_client: Object.new)

    error = assert_raises(ArgumentError) { client.price_for(slug: "  ") }

    assert_equal "slug is required", error.message
  end

  test "price_for translates non-success responses into a stable client error" do
    http_client = fake_http(Response.new(429, '{"status":"rate limited"}'))
    client = CoinMarketCapClient.new(api_key: "configured-key", http_client: http_client)

    error = assert_raises(CoinMarketCapClient::Error) do
      client.price_for(slug: "bitcoin")
    end

    assert_equal "CoinMarketCap returned HTTP 429", error.message
    refute_includes error.message, "configured-key"
  end

  test "price_for rejects malformed JSON" do
    client = CoinMarketCapClient.new(
      api_key: "configured-key",
      http_client: fake_http(Response.new(200, "not-json"))
    )

    error = assert_raises(CoinMarketCapClient::Error) do
      client.price_for(slug: "bitcoin")
    end

    assert_equal "CoinMarketCap returned malformed JSON", error.message
  end

  test "price_for rejects successful responses without a USD price" do
    body = { data: { "1" => { quote: { USD: {} } } } }.to_json
    client = CoinMarketCapClient.new(
      api_key: "configured-key",
      http_client: fake_http(Response.new(200, body))
    )

    error = assert_raises(CoinMarketCapClient::Error) do
      client.price_for(slug: "bitcoin")
    end

    assert_equal "CoinMarketCap response did not include a USD price", error.message
  end

  test "price_for rejects valid JSON with a non-object top level" do
    ["null", "[]"].each do |body|
      client = CoinMarketCapClient.new(
        api_key: "configured-key",
        http_client: fake_http(Response.new(200, body))
      )

      error = assert_raises(CoinMarketCapClient::Error) do
        client.price_for(slug: "bitcoin")
      end

      assert_equal "CoinMarketCap response did not include a USD price", error.message
    end
  end

  test "price_for translates request timeouts without leaking credentials" do
    http_client = Object.new
    http_client.define_singleton_method(:get) do |_url, _options|
      raise Timeout::Error, "upstream timed out"
    end
    client = CoinMarketCapClient.new(api_key: "configured-key", http_client: http_client)

    error = assert_raises(CoinMarketCapClient::Error) do
      client.price_for(slug: "bitcoin")
    end

    assert_match "CoinMarketCap request failed", error.message
    assert_match "Timeout::Error", error.message
    refute_includes error.message, "configured-key"
  end

  private

  def fake_http(response)
    Object.new.tap do |client|
      client.define_singleton_method(:get) { |_url, _options| response }
    end
  end
end
