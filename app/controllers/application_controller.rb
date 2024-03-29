class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

	def after_sign_in_path_for(resource)
    # Here you can write logic based on roles to return different after sign in paths
    if current_user.patient?
      patient_dashboard_path
    else
      doctor_dashboard_path
    end
  end

	protected

	def configure_permitted_parameters
    attributes = [:firstname, :lastname, :mobile_number, :birthdate, :login, :email]
    devise_parameter_sanitizer.permit(:sign_up, keys: attributes)
    devise_parameter_sanitizer.permit :sign_in, keys: [:mobile_number, :password, :login]
    devise_parameter_sanitizer.permit(:account_update, keys: attributes)
  end
end
