require 'test_helper'

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should post search" do
    post search_url
    assert_response :success
  end

  test "should post calculate" do
    post calculate_url
    assert_response :success
  end
end
