require "test_helper"

class ClinicSpecialCasesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get clinic_special_cases_create_url
    assert_response :success
  end

  test "should get update" do
    get clinic_special_cases_update_url
    assert_response :success
  end
end
