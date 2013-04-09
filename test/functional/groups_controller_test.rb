require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
    @group = groups(:admins)
  end

  test "should get index" do
    sign_in @user
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  test "should get new" do
    sign_in @user
    get :new
    assert_response :success
  end

  test "should create group" do
    sign_in @user
    assert_difference('Group.count') do
      post :create, group: { description: 'Opis', name: 'test2', title: 'Test group' }
    end
    assert_redirected_to group_path(assigns(:group))
  end

  test "should show group" do
    sign_in @user
    get :show, id: @group
    assert_response :success
  end

  test "should get edit" do
    sign_in @user
    get :edit, id: @group
    assert_response :success
  end

  test "should update group" do
    sign_in @user
    put :update, id: @group, group: { description: 'Administration', title: 'Administration' }
    assert_redirected_to group_path(assigns(:group))
  end

  test "should destroy group" do
    sign_in @user
    assert_difference('Group.count', -1) do
      delete :destroy, id: groups(:test)
    end

    assert_redirected_to groups_path
  end
end
