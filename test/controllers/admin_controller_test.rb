require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @writing = writings(:one)
  end

  test "should get index" do
    get admin_url
    assert_response :success
  end

  test "should get users" do
    get admin_users_url
    assert_response :success
  end

  test "should get writings" do
    get admin_writings_url
    assert_response :success
  end

  test "should get show_writing" do
    get admin_writing_url(@writing)
    assert_response :success
  end
end
