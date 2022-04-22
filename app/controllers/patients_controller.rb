class PatientsController <  ApplicationController
  before_action :authenticate_user!
  before_action :set_patient, only: %i[ show edit update destroy ] # only: %i[ dashboard book_appointment ]
  before_action :set_patients #, only: %i[ dashboard book_appointment ]
  # before_action :authenticate_patient!

  def index
    @patients = User.where(role: 1)
  end

  def new
    @patient = Patient.new
  end

  # GET /patients/1/edit
  def edit
  end

  def book_patient_appointment
    user = current_user
    app_sched = params[:patient][:appointment_schedule]

    clinic, wday, time, ampm, date = app_sched.split("\s",5)
    clinic_id = Clinic.find_by(name: clinic).id
    dt = DateTime.parse(date + " " + time + " " + ampm)

    @appointment = user.appointments.new(
      schedule: dt,
      clinic_id: clinic_id
    )

    if @appointment.save
      redirect_to patient_book_appointment_url, notice: "Appointment set successfully!"
    else
      redirect_to patient_book_appointment_url, alert: " #{@appointment.errors.first.full_message}"
    end
  end

  # POST /patients or /patients.json
  def create

    # this if block is a kludge; i do not know why rails does not understand fully enums
    if (my_role = params[:role])&.to_i != 0
      params[:role] = Patient.roles.find{|k,v| v==params[:role].to_i}.first
    end

    @user = User.new(
      email: params[:email],
      firstname: params[:firstname],
      lastname: params[:lastname],
      mobile_number: params[:mobile_number],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    respond_to do |format|
      if @user.save
        if current_user.doctor?
          format.html { redirect_to patients_url, notice: "Patient created successfully!" }
          # format.json { render :show, status: :created, location: @patient }
        end
      else
        if current_user.doctor?
          format.html { redirect_to patients_url, alert: "Appointment was not created. #{@appointment.errors.first.full_message}" }
          # format.json { render json: @patient.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /patients/1 or /patients/1.json
  def update
    user = User.find(@patient.id)
    respond_to do |format|
      if user.update(patient_params)
        format.html { redirect_to patients_url, notice: "Patient was successfully updated." }
        format.json { render :show, status: :ok, location: user}
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patients/1 or /patients/1.json
  def destroy
    user = User.find(@patient.id)
    user.destroy

    respond_to do |format|
      format.html { redirect_to patients_url, notice: "Patient was successfully destroyed." }
      format.json { head :no_content }
    end
  end



  def dashboard
    patient = current_user
    @appointments_to_attend = patient.appointments.where('schedule > ?', Time.now.utc)
  end

  def my_appointments
    @appointments = current_user.appointments
  end

  def create_appointment
    @appointment = current_patient.appointments.new(
      schedule: params[:schedule],
      user_id: current_patient.id,
      clinic_id: params[:clinic_id]
    )
    if @appointment.save
      UserMailer.with(user: current_patient).appointment_created.deliver_now
      redirect_to patient_book_appointment_url, notice: "Appointment set successfully!"
    else
      redirect_to patient_book_appointment_url, notice: "Appointment was not created. #{@appointment.errors.first.full_message}"
    end
  end

  def week_appointments
    # start = Time.zone.now
    @appointments = Appointment.current_week
  end

  def book_appointment
		@clinics = Clinic.all
		@clinic = Clinic.first
		@clinic = Clinic.find(params[:clinic_id]) if params[:clinic_id].present?
    @patient = Patient.new()
    @patients = Patient.all
  end

  def book_existing_patient_appointment
    @appointment = current_user.appointments.new(
      schedule: params[:patient][:appointment_schedule],
      clinic_id: params[:patient][:clinic_id]
    )

    if @appointment.save
      redirect_to patient_book_appointment_url, notice: "Appointment set successfully!"
    else
      redirect_to patient_book_appointment_url, alert: " #{@appointment.errors.first.full_message}"
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id]) # || current_patient
  end

  def set_patients
    @patients = Patient.my_default_scope #.all
  end

  def current_patient
    @patient = current_user
  end

  # Only allow a list of trusted parameters through.
  def patient_params
    params.require(:patient).permit(:email, :firstname, :lastname, :birthdate, :gender, :mobile_number, :role, :password, :password_confirmation)
  end

end
