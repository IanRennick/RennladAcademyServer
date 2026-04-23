require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:Bob)
  end

  test "should get profile" do
    get user_path(@user)
    assert_response :success
  end
end
