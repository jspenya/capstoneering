class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    patient_dashboard_path
  end
end
