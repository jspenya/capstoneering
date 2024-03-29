class UsersController < ApplicationController
  before_action :set_user, only: %i[ edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    if @user.update(user_params)
      if @user.doctor? || @user.secretary?
        redirect_to doctor_dashboard_url, notice: 'Account successfully updated!'
      else
        redirect_to patient_dashboard_url, notice: 'Account successfully updated!'
      end
    else
      redirect_to edit_user_path(@user), alert: "#{@user.errors.first.full_message}"
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to doctor_staffs_url, notice: "User was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      params.require(:user).permit(:email, :firstname, :lastname, :birthdate, :gender, :role, :password, :password_confirmation, :login, :mobile_number)
    end
end
