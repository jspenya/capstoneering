class Doctors::ClinicQueuesController < DoctorsController
	before_action :authenticate_user!
  before_action :set_clinic

	def index
		@clinics = Clinic.all
		@clinic_queues = ClinicQueue.queue_today.order(:schedule)

		@patient  = Patient.new
		@patients = Patient.all
	end

	def create
		@patient = Patient.new(patient_params)
    if @patient.save
      @clinic_queue = ClinicQueue.create!(schedule: DateTime.now, user_id: @patient.id)

      redirect_to doctor_queue_path, notice: "Patient created successfully!"
    else
      redirect_to patient_book_appointment_url, notice: "Patient not created!! #{@patient.errors.first.full_message}"
    end
	end

	def add_existing_patient_to_queue
		user = User.find_by(email: params[:patient][:email])

		@clinic_queue = user.clinic_queues.new(schedule: DateTime.now, clinic_id: @clinic.id, queue_type: 1)

    if @clinic_queue.save
      redirect_to doctor_clinic_queues_url, notice: "Patient added to queue successfully!"
    else
      redirect_to doctor_clinic_queues_url, alert: "There was a problem in adding patient to queue. #{@clinic_queue.errors.first.full_message}"
    end
	end

	def add_patient_to_queue
    @patient = Patient.new(
			firstname: params[:patient][:firstname],
			lastname: params[:patient][:lastname],
			email: params[:patient][:email],
			password: params[:patient][:password],
			password_confirmation: params[:patient][:password_confirmation]
		)

    if @patient.save
			user = User.find(@patient.id)

      @clinic_queue = ClinicQueue.create!(schedule: DateTime.now, user_id: user.id, clinic_id: @clinic.id, queue_type: 1)
      redirect_to doctor_clinic_queues_url, notice: "Patient added to queue successfully!"
    else
      redirect_to doctor_clinic_queues_url, alert: "There was a problem in adding patient to queue. #{@clinic_queue.errors.first.full_message}"
    end
  end

	def destroy
		@clinic_queue = ClinicQueue.find(params[:id])
		@clinic_queue.destroy

		redirect_to doctor_clinic_queues_url, notice: "Successfully removed from queue!"
	end

	private
	def set_clinic
		clinic_id = ClinicSchedule.where(day: Date.today.strftime("%A")).first.clinic_id

		@clinic = Clinic.find(clinic_id)
	end
end
