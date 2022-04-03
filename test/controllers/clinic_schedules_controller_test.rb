require "test_helper"

class ClinicSchedulesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get clinic_schedules_new_url
    assert_response :success
  end

  test "should get create" do
    get clinic_schedules_create_url
    assert_response :success
  end
end
