require "socket"
require "timeout"

class CoinMarketCapClient
  class Error < StandardError; end

  API_KEY_ENV = "COINMARKETCAP_API_KEY".freeze
  ENDPOINT = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest".freeze
  REQUEST_TIMEOUT_SECONDS = 5

  def initialize(api_key: ENV[API_KEY_ENV], http_client: HTTParty)
    if api_key.nil? || api_key.strip.empty?
      raise KeyError, "#{API_KEY_ENV} is not configured"
    end

    @api_key = api_key
    @http_client = http_client
  end

  def price_for(slug:)
    if slug.nil? || slug.to_s.strip.empty?
      raise ArgumentError, "slug is required"
    end

    response = @http_client.get(
      ENDPOINT,
      query: { slug: slug },
      headers: {
        "Accept" => "application/json",
        "X-CMC_PRO_API_KEY" => @api_key
      },
      timeout: REQUEST_TIMEOUT_SECONDS
    )

    unless response.code.to_i.between?(200, 299)
      raise Error, "CoinMarketCap returned HTTP #{response.code.to_i}"
    end

    payload = JSON.parse(response.body)
    price = extract_usd_price(payload)

    raise Error, "CoinMarketCap response did not include a USD price" if price.nil?

    price
  rescue JSON::ParserError
    raise Error, "CoinMarketCap returned malformed JSON"
  rescue Timeout::Error, SocketError, SystemCallError => error
    raise Error, "CoinMarketCap request failed: #{error.class}"
  end

  private

  def extract_usd_price(payload)
    data = payload["data"]
    return unless data.is_a?(Hash)

    currency = data.values.first
    return unless currency.is_a?(Hash)

    currency.dig("quote", "USD", "price")
  end
end
