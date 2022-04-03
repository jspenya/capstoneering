class DoctorsController <  ApplicationController
  before_action :set_patient, only: %i[ show edit update destroy ] # only: %i[ dashboard book_appointment ]
  before_action :set_patients #, only: %i[ dashboard book_appointment ]
  # before_action :authenticate_patient!
  # before_action :setup_queue_index, only: [:queue_show]
  # autocomplete :patient, :term
  # before_action :force_json, only: :search

  def search
    # @patients = Patient.where(lastname: params[:query])
    @patients = Patient.ransack(lastname_cont: params[:q]).result.limit(5)

    respond_to do |format|
      format.html {  }
      format.json {
        @patients = @patients.limit(5)
      }
    end
  end

  def dashboard
    @appointments = Appointment.all

    @appointments_to_attend = @appointments.where('schedule > ?', DateTime.now)
    @appointments_served = @appointments.where('schedule < ? AND schedule > ?', DateTime.now, DateTime.now.beginning_of_day)
  end

  def new
    @patient = Patient.new
  end

  # GET /patients/1/edit
  def edit
  end

  # POST /patients or /patients.json
  def create

    # this if block is a kludge; i do not know why rails does not understand fully enums
    # if (my_role = params[:patient][:role])&.to_i != 0
    #   params[:patient][:role] = Patient.roles.find{|k,v| v==params[:patient][:role].to_i}.first
    # end

    @patient = Patient.new(patient_params)

    respond_to do |format|
      if @patient.save
        format.html { redirect_to doctor_dashboard, notice: "Patient was successfully created." }
        # format.json { render :show, status: :created, location: @patient }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /patients/1 or /patients/1.json
  def update
    respond_to do |format|
      if @patient.update(patient_params)
        format.html { redirect_to patient_url(@patient), notice: "Patient was successfully updated." }
        format.json { render :show, status: :ok, location: @patient }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patients/1 or /patients/1.json
  def destroy
    @patient.destroy

    respond_to do |format|
      format.html { redirect_to patients_url, notice: "Patient was successfully destroyed." }
      format.json { head :no_content }
    end
  end



  # def dashboard
  #   patient = current_user
  #   @appointments_to_attend = patient.appointments.where('schedule > ?', DateTime.now)
  # end

	def book_appointment
		@clinics = Clinic.all
		@clinic = Clinic.first
		@clinic = Clinic.find(params[:clinic_id]) if params[:clinic_id].present?

    # respond_to do |format|
    #   format.html {  }
    #   format.js
    # end
    @patient = Patient.new()
    @patients = Patient.all
  end

  def book_existing_patient_appointment
    user = User.find_by(email: params[:patient][:email])

    @appointment = user.appointments.new(
      schedule: params[:patient][:appointment_schedule],
      clinic_id: params[:patient][:clinic_id]
    )

    if @appointment.save
      redirect_to doctor_book_appointment_url, notice: "Appointment set successfully!"
    else
      redirect_to doctor_book_appointment_url, alert: " #{@appointment.errors.first.full_message}"
    end
  end

  def book_patient_appointment
    @patient = Patient.new(
     firstname: params[:patient][:firstname],
     lastname: params[:patient][:lastname],
     email: params[:patient][:email],
     password: params[:patient][:password],
     password_confirmation: params[:patient][:password_confirmation]
    )

    if @patient.save
      user = User.find(@patient.id)
      @appointment = user.appointments.new(
        schedule: params[:patient][:appointment_schedule],
        clinic_id: params[:patient][:clinic_id]
      )
      if @appointment.save
        redirect_to doctor_book_appointment_url, notice: "Appointment set successfully!"
      else
        redirect_to doctor_book_appointment_url, alert: " #{@appointment.errors.first.full_message}"
      end
    else
      redirect_to doctor_book_appointment_url, alert: "There was an error in creating your appointment!"
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

  def patients_index
    @patient = Patient.new
  end

  def clinics_index
    @clinics = Clinic.all
    @clinic = Clinic.new

    @clinic_schedules = ClinicSchedule.all
    @days_of_the_week = Date::DAYNAMES
  end


  def autocomplete
    results = AutocompleteSearchService.new(params[:q]).call
    render json: results
  end

  def autocomplete_patient
    term = params[:term]
    terms = make_terms_from term
    @patients = Patient.where(terms)
    render :json => @patients.map { |patient| {:id => patient.id, :label => patient.fullname, :value => patient.fullname} }
  end

  def make_terms_from term
    terms = term.split.map{|t| "mobile_number ilike '%%%s%%'" % t}.join(" or ")
  end

  def queue_index
    @clinic_queues = ClinicQueue.where(schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day)
    @patient = Patient.new
    @patients = Patient.pluck(:lastname).sort


    # clinic_queue = Clinic.create(
    #   user: @patient
    # )

    @patients = Patient.all
  end

  def setup_queue_index
    # byebug
    if ClinicQueue.find_by(schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day ).present?
      clinic_queue_id = ClinicQueue.find_by( schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day ).id
    else
      clinic_queue = ClinicQueue.create(schedule: DateTime.now.beginning_of_day)

      clinic_queue_id = clinic_queue.id
    end

    redirect_to action: :queue_show, id: clinic_queue_id
  end

  def create_clinic_schedule

  end

  private

  def force_json
    request.format = :json
  end

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
    params.require(:patient).permit(:email, :firstname, :lastname, :birthdate, :gender, :mobile_number, :password, :password_confirmation, :role )
  end

  def clinic_queue_params
    params.require(:clinic_queue).permit(:user_id)
  end
end
