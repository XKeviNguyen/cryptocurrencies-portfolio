class Currency < ApplicationRecord
  COINMARKETCAP_API_KEY_ENV = "COINMARKETCAP_API_KEY".freeze

  def calculate_value(amount)
    current_price.to_f * amount.to_f
  end

  def current_price
    headers = {
      "X-CMC_PRO_API_KEY" => coinmarketcap_api_key
    }
    url = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?slug=#{slug}"
    request = HTTParty.get(
      url,
      'Content-Type' => 'application/json',
      :headers => headers
    )
    response = JSON.parse(request.body)
    id = get_id(response.dig('data')).first
    response.dig('data', id, 'quote', 'USD', 'price')
  end

  def get_id(data)
    data.keys
  end

  private

  def coinmarketcap_api_key
    ENV.fetch(COINMARKETCAP_API_KEY_ENV) do
      raise KeyError, "#{COINMARKETCAP_API_KEY_ENV} is not configured"
    end
  end
end
