require 'test_helper'

class TransferFilesControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
  end

  test "should post file on json request" do
    sign_in @user
    post :create, object: fixture_file_upload('apple.jpg'), transfer: { group_token: SecureRandom.hex(8) }, format: :json
    assert_response :success
  end

  test "should delete file on js request" do
    sign_in @user
    delete :destroy, id: transfer_files(:one), format: :js
    assert_response :success
  end

end
