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
end
