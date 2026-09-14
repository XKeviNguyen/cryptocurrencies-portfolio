require 'test_helper'
require 'minitest/mock'

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should post search" do
    post search_url, params: { search: 'mystring' }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 2, payload.fetch('currencies').size
  end

  test "search returns an empty result for missing or blank queries" do
    [nil, '', '   '].each do |query|
      post search_url, params: { search: query }

      assert_response :success
      assert_equal [], JSON.parse(response.body).fetch('currencies')
    end
  end

  test "search treats SQL LIKE wildcards as literal input" do
    percent_currency = Currency.create!(name: '100% Coin', slug: 'percent-coin')
    Currency.create!(name: '100X Coin', slug: 'plain-coin')

    post search_url, params: { search: '%' }

    assert_response :success
    ids = JSON.parse(response.body).fetch('currencies').map { |currency| currency.fetch('id') }
    assert_equal [percent_currency.id], ids
  end

  test "search rejects oversized queries" do
    post search_url, params: { search: 'a' * 81 }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal 'invalid_search', payload.dig('error', 'code')
  end

  test "search is deterministic and bounded" do
    30.times do |index|
      Currency.create!(name: format('Bounded Coin %02d', 29 - index), slug: "bounded-#{index}")
    end

    post search_url, params: { search: 'bounded coin' }

    assert_response :success
    names = JSON.parse(response.body).fetch('currencies').map { |currency| currency.fetch('name') }
    assert_equal 25, names.size
    assert_equal names.sort_by(&:downcase), names
    assert_equal 'Bounded Coin 00', names.first
    assert_equal 'Bounded Coin 24', names.last
  end

  test "should post calculate" do
    currency = currencies(:one)
    price_lookups = 0

    Currency.stub :find, currency do
      currency.stub :current_price, -> { price_lookups += 1; 2.0 } do
        post calculate_url, params: { id: currency.id, amount: 3 }
      end
    end

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 2.0, payload.fetch('current_price')
    assert_equal 6.0, payload.fetch('value')
    assert_equal 1, price_lookups
  end

  test "calculate preserves valid fractional holdings" do
    currency = currencies(:one)

    Currency.stub :find, currency do
      currency.stub :current_price, 40_000.0 do
        post calculate_url, params: { id: currency.id, amount: '0.125' }
      end
    end

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal '0.125', payload.fetch('amount')
    assert_equal 5_000.0, payload.fetch('value')
  end

  test "calculate rejects malformed and non-positive amounts before price lookup" do
    currency = currencies(:one)

    invalid_amounts = [
      nil,
      '',
      'abc',
      'NaN',
      'Infinity',
      '0',
      '-0.01',
      '1_0',
      '1_',
      '1e3',
      '1' + ('0' * 400),
      '0.' + ('0' * 400) + '1'
    ]

    invalid_amounts.each do |amount|
      price_lookups = 0

      Currency.stub :find, currency do
        currency.stub :current_price, -> { price_lookups += 1; 2.0 } do
          post calculate_url, params: { id: currency.id, amount: amount }
        end
      end

      assert_response :unprocessable_entity
      payload = JSON.parse(response.body)
      assert_equal 'invalid_amount', payload.dig('error', 'code')
      assert_equal 0, price_lookups
    end
  end

  test "calculate returns a stable service unavailable response for market data failures" do
    currency = currencies(:one)

    Currency.stub :find, currency do
      currency.stub :current_price, -> { raise CoinMarketCapClient::Error, 'upstream detail' } do
        post calculate_url, params: { id: currency.id, amount: '1.5' }
      end
    end

    assert_response :service_unavailable
    payload = JSON.parse(response.body)
    assert_equal 'market_data_unavailable', payload.dig('error', 'code')
    assert_equal 'Market price is temporarily unavailable', payload.dig('error', 'message')
    refute_includes response.body, 'upstream detail'
  end

  test "calculate treats missing market data configuration as unavailable" do
    currency = currencies(:one)

    Currency.stub :find, currency do
      currency.stub :current_price, -> { raise KeyError, 'COINMARKETCAP_API_KEY is not configured' } do
        post calculate_url, params: { id: currency.id, amount: '1' }
      end
    end

    assert_response :service_unavailable
    payload = JSON.parse(response.body)
    assert_equal 'market_data_unavailable', payload.dig('error', 'code')
    refute_includes response.body, 'COINMARKETCAP_API_KEY'
  end
end
