#encoding: utf-8
require 'test_helper'


class TransfersControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
  end

  test "should get index" do
    sign_in @user
    get :index
    assert_response :success
  end

  test "should upload file" do
    sign_in @user
    get :index

    token = css_select('#transfer_group_token').first.attributes['value']

    assert_difference('Transfer.count') do
      post :create, transfer: { name: 'Nazwa', recipients: 'bartek@1000i.pl', group_token: token }, format: :js
    end
    assert_response :success
  end
end
