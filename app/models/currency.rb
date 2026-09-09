class Currency < ApplicationRecord
  def calculate_value(amount)
    current_price.to_f * amount.to_f
  end

  def current_price(client: CoinMarketCapClient.new)
    client.price_for(slug: slug)
  end
end
