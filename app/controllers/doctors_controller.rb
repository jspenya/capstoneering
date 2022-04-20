class DoctorsController <  ApplicationController
  before_action :authenticate_user!
  before_action :set_patient, only: %i[ show edit update destroy ] # only: %i[ dashboard book_appointment ]
  before_action :set_patients #, only: %i[ dashboard book_appointment ]
  before_action :set_secretaries #, only: %i[ dashboard book_appointment ]
  # before_action :authenticate_patient!
  # before_action :setup_queue_index, only: [:queue_show]
  autocomplete :patient, :email
  # before_action :force_json, only: :search

  def autocomplete_patient
    term = params[:term]
    terms = make_terms_from term

    patients = Patient.where(terms).all
    render :json => patients.map { |d| {:id => d.id, :label => d.fullname_and_email, :value => d.fullname_and_email} }
  end

  def make_terms_from term
    terms = term.split.map{|t| "lastname ilike '%%%s%%'" % t}.join(" or ")
  end

  def autocomplete_schedule
    term = params[:term]
    terms = term.split

    str = terms.join('.*?\s')
    re = Regexp.new(str, Regexp::IGNORECASE)
    as = available_slots.grep re
    render :json => as.map{ |s| { :label => s, :value => s } }
  end

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

    @appointments_to_attend = @appointments.where('schedule > ?', Time.now.utc)
    @appointments_served = @appointments.where('schedule < ? AND schedule > ?', Time.now.utc, Time.now.utc.beginning_of_day)
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

  def destroy_clinic
    clinic = Clinic.find(params[:id])
    clinic.destroy

    redirect_to doctor_clinics_path, notice: "Clinic successfully deleted."
  end

	def book_appointment
		@clinics = Clinic.all
    @patient = Patient.new()
    @patients = Patient.all
    # @clinic_schedules =
  end

  def book_existing_patient_appointment
    user_field = params[:patient][:email]
    f_name, l_name, email = user_field.split(" ")

    user = User.find_by(email: email)
    app_sched = params[:patient][:appointment_schedule]

    clinic, wday, time, ampm, date = app_sched.split("\s",5)
    clinic_id = Clinic.find_by(name: clinic).id
    dt = DateTime.parse(date + " " + time + " " + ampm)

    @appointment = user.appointments.new(
      schedule: dt,
      clinic_id: clinic_id
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
     mobile_number: params[:patient][:mobile_number],
     password: params[:patient][:password],
     password_confirmation: params[:patient][:password_confirmation]
    )

    if @patient.save
      user = User.find(@patient.id)
      app_sched = params[:patient][:appointment_schedule]

      clinic, wday, time, ampm, date = app_sched.split("\s",5)
      clinic_id = Clinic.find_by(name: clinic).id
      dt = DateTime.parse(date + " " + time + " " + ampm)

      @appointment = user.appointments.new(
        schedule: dt,
        clinic_id: clinic_id
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

  def staffs_index
    @secretary = Secretary.new
  end

  def create_staff
    @secretary = Secretary.new(secretary_params)

    if @secretary.save
      redirect_to doctor_staffs_path, notice: "Staff successfully created!"
    else
      redirect_to doctor_staffs_path, alert: "There was an error. #{@secretary.errors.first.full_message}"
    end
  end

  def clinics_index
    @clinics = Clinic.all
    @clinic = Clinic.new

    @clinic_schedules = ClinicSchedule.all
    @days_of_the_week = Date::DAYNAMES
  end

  # def make_terms_from term
  #   terms = term.split.map{|t| "mobile_number ilike '%%%s%%'" % t}.join(" or ")
  # end

  def queue_index
    @clinic_queues = ClinicQueue.where(schedule: Time.now.utc.beginning_of_day..Time.now.utc.end_of_day)
    @patient = Patient.new
    @patients = Patient.pluck(:lastname).sort


    # clinic_queue = Clinic.create(
    #   user: @patient
    # )

    @patients = Patient.all
  end

  def setup_queue_index
    # byebug
    if ClinicQueue.find_by(schedule: Time.now.utc.beginning_of_day..Time.now.utc.end_of_day ).present?
      clinic_queue_id = ClinicQueue.find_by( schedule: Time.now.utc.beginning_of_day..Time.now.utc.end_of_day ).id
    else
      clinic_queue = ClinicQueue.create(schedule: Time.now.utc.beginning_of_day)

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

  def set_secretaries
    @secretaries = Secretary.my_default_scope #.all
  end

  def current_patient
    @patient = current_user
  end

  # Only allow a list of trusted parameters through.
  def patient_params
    params.require(:patient).permit(:email, :firstname, :lastname, :birthdate, :gender, :mobile_number, :password, :password_confirmation, :role )
  end

  def secretary_params
    params.require(:secretary).permit(:email, :firstname, :lastname, :birthdate, :gender, :mobile_number, :password, :password_confirmation, :role)
  end

  def clinic_queue_params
    params.require(:clinic_queue).permit(:user_id)
  end

  def time_iterate(start_time, end_time, step, &block)
    begin
      yield(start_time)
    end while (start_time += step) <= end_time
  end

  def available_slots
    c =
      Clinic.all.map{|c|
        [c.clinic_schedules.map{ |cs|
            (
              x = []
              time_iterate(cs.start_time, cs.end_time, c.appointment_duration.minutes) do |dt|
                x << [ c.name + " " + cs.day + " " + dt.strftime("%l:%M %p") ]
              end
              if current_user.doctor? || current_user.secretary?
                x
              else
                if special_case = cs.clinic_special_cases.find_by(day: Date.today)
                  x.take(special_case.slots)
                else
                  x.take(15)
                end
              end
            )
          }
        ]
      }.flatten

    d = Date.today..Date.today.end_of_month.next_month
    y = d.map{ |d|
      dow = d.strftime("%A")
      a_d = c.grep /#{dow}/i

      a_d.map{|a| a + " " + d.strftime("%B %e %Y") }
      }

    array_of_all_slots = y.flatten

    days_taken = Appointment.current_month.map{ |a|
      cname = Clinic.find( a.clinic_id ).name
      t = a.schedule.strftime("%l:%M %p")
      aday = a.schedule.strftime("%A")
      adate = a.schedule.to_date.strftime("%B %e %Y")

      [cname, aday, t, adate].join(" ")
    }

    available_slots = array_of_all_slots - days_taken
  end
end
