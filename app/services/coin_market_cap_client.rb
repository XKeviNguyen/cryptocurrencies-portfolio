require "openssl"
require "socket"
require "timeout"

class CoinMarketCapClient
  class Error < StandardError; end

  API_KEY_ENV = "COINMARKETCAP_API_KEY".freeze
  ENDPOINT = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest".freeze
  REQUEST_TIMEOUT_SECONDS = 5

  def initialize(api_key: ENV[API_KEY_ENV], http_client: HTTParty, request_timeout_seconds: REQUEST_TIMEOUT_SECONDS)
    if api_key.nil? || api_key.strip.empty?
      raise KeyError, "#{API_KEY_ENV} is not configured"
    end

    @api_key = api_key
    @http_client = http_client
    @request_timeout_seconds = request_timeout_seconds
  end

  def price_for(slug:)
    normalized_slug = slug.to_s.strip.downcase
    raise ArgumentError, "slug is required" if normalized_slug.empty?

    Timeout.timeout(@request_timeout_seconds) do
      response = @http_client.get(
        ENDPOINT,
        query: { slug: normalized_slug },
        headers: {
          "Accept" => "application/json",
          "X-CMC_PRO_API_KEY" => @api_key
        },
        timeout: @request_timeout_seconds
      )

      unless response.code.to_i.between?(200, 299)
        raise Error, "CoinMarketCap returned HTTP #{response.code.to_i}"
      end

      payload = JSON.parse(response.body)
      quote = extract_quote(payload, requested_slug: normalized_slug)
      price = quote.dig("quote", "USD", "price")

      unless valid_price?(price)
        raise Error, "CoinMarketCap response included an invalid USD price"
      end

      price
    end
  rescue JSON::ParserError
    raise Error, "CoinMarketCap returned malformed JSON"
  rescue Timeout::Error, SocketError, SystemCallError, EOFError, OpenSSL::SSL::SSLError => error
    raise Error, "CoinMarketCap request failed: #{error.class}"
  end

  private

  def extract_quote(payload, requested_slug:)
    unless payload.is_a?(Hash) && payload["data"].is_a?(Hash)
      raise Error, "CoinMarketCap response did not include the requested asset"
    end

    quote = payload["data"].values.find do |currency|
      currency.is_a?(Hash) && currency["slug"].to_s.downcase == requested_slug
    end

    raise Error, "CoinMarketCap response did not include the requested asset" unless quote

    quote
  end

  def valid_price?(price)
    price.is_a?(Numeric) && price.finite? && price.positive?
  end
end
