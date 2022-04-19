class ClinicsController <  ApplicationController
  # before_action :authenticate_patient!
  before_action :set_clinic, only: [:edit, :update, :destroy]

  def new
    @clinic = Clinic.new
  end

  # GET /patients/1/edit
  def edit
    @clinic = Clinic.find(params[:id])
  end

  # POST /patients or /patients.json
  def create
    # If clinic name is more than 1 word
    # we have to underscorize in order
    # for us to query properly in autocomplete
    clinic_name = params[:clinic][:name].split(" ").map{|c| c.capitalize}.join('_')

    @clinic = Clinic.new(
      name: clinic_name,
      user_id: params[:clinic][:user_id],
      room_number: params[:clinic][:room_number],
      appointment_duration: params[:clinic][:appointment_duration]
    )

    respond_to do |format|
      if @clinic.save
        format.html { redirect_to doctor_clinics_url, notice: "Clinic was successfully created." }
      else
        format.html { redirect_to doctor_clinics_url, alert: "There was an error in creating the clinic. #{@clinic.errors.first.full_message}"}
      end
    end
  end

  # PATCH/PUT /patients/1 or /patients/1.json
  def update
    # If clinic name is more than 1 word
    # we have to underscorize in order
    # for us to query properly in autocomplete
    clinic_name = params[:clinic][:name].split(" ").map{|c| c.capitalize}.join('_')

    respond_to do |format|
      if @clinic.update(
        name: clinic_name,
        room_number: params[:clinic][:room_number],
        appointment_duration: params[:clinic][:appointment_duration]
      )
        format.html { redirect_to doctor_clinics_url, notice: "Clinic was successfully updated." }
        format.json { render :show, status: :ok, location: @clinic }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @clinic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patients/1 or /patients/1.json
  def destroy
    @clinic.destroy

    respond_to do |format|
      format.html { redirect_to clinics_url, notice: "Clinic was successfully destroyed." }
      format.json { head :no_content }
    end
  end



  def dashboard
    patient = current_user
    @appointments_to_attend = patient.appointments.where('schedule > ?', Time.now.utc)
  end

	def book_appointment
		Rails.logger.info("Heeeeeere") if params[:week].present?
		@clinics = Clinic.all
		@clinic = Clinic.first
		@clinic = Clinic.find(params[:clinic_id]) if params[:clinic_id].present?

    respond_to do |format|
      format.html {  }
      format.js
    end
  end

  def create_appointment
    @appointment = current_patient.appointments.new(
      schedule: params[:schedule],
      user_id: current_patient.id,
      clinic_id: params[:clinic_id]
    )
    if @appointment.save
      redirect_to patient_book_appointment_url, notice: "Appointment set successfully!"
    else
      redirect_to patient_book_appointment_url, notice: "Appointment was not created. #{@appointment.errors.first.full_message}"
    end
  end

  def week_appointments
    # start = Time.zone.now
    @appointments = Appointment.current_week
  end



  private

  def set_clinic
    @clinic = Clinic.find(params[:id])
  end

  def set_patients
    @clinics = Patient.my_default_scope #.all
  end

  def current_patient
    @clinic = current_user
  end

  # Only allow a list of trusted parameters through.
  def patient_params
    params.require(:patient).permit(:email, :firstname, :lastname, :birthdate, :gender, :role)
  end

  def clinic_params
    params.require(:clinic).permit(:user_id, :name, :room_number, :status, :appointment_duration)
  end
  
  def set_ariane
    super
    ariane.add 'Clinic Schedules', clinic_clinic_schedules_path
  end
end
