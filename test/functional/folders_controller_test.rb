require 'test_helper'

class FoldersControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
    @folder = folders(:global_subfolder)
  end

  test "should get share" do
    sign_in @folder.user
    put :share, id: folders(:admin).id, format: :js
    assert_response :success
  end

  test "should get create" do
    sign_in @folder.user
    post :create, folder: {name: 'Nowy folder', parent: folders(:global)}, format: :js
    assert_response :success
  end

  test "should get destroy" do
    sign_in @folder.user
    delete :destroy, id: @folder.id, format: :js
    assert_response :success
  end

end
