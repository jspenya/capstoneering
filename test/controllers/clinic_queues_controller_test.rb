require "test_helper"

class ClinicQueuesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get clinic_queues_show_url
    assert_response :success
  end

  test "should get edit" do
    get clinic_queues_edit_url
    assert_response :success
  end

  test "should get update" do
    get clinic_queues_update_url
    assert_response :success
  end
end
