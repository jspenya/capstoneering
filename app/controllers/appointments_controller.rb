class AppointmentsController < ApplicationController
	before_action :set_appointment, only: %i[ show edit update destroy ]
	before_action :set_patients, only: %i[ new ]

	def new
		@appointment = Appointment.new
		@clinics = Clinic.all
	end

  def autocomplete_schedule
    term = params[:term]
    terms = term.split
    
    str = terms.join('.*?\s')
    re = Regexp.new(str, Regexp::IGNORECASE)  
    as = available_slots.grep re
    render :json => as.map{ |s| { :label => s, :value => s } }
  end

	def create
    byebug
    password_hex = SecureRandom.hex(5)

    @patient = Patient.new(
      firstname: params[:firstname],
      lastname: params[:lastname],
      email: params[:email],
      encrypted_password: User.new(password: password_hex).encrypted_password,
    )

    if @patient.save
      user = User.find(@patient.id)
      app_sched = params[:patient][:appointment_schedule]
    else
    end

    respond_to do |format|
      if @appointment.save
				if current_user.doctor?
					format.html { redirect_to doctor_book_appointment_path, notice: "Appointment successfully set." }
					# format.json { render :show, status: :created, location: @appointment }
				end
        redirect_to root_path, notice: "Appointment set successfully! Please check your SMS inbox or email for your appointment details."
      else
				if current_user.doctor?
					format.html { redirect_to doctor_book_appointment_path, alert: "Appointment was not created. #{@appointment.errors.first.full_message}" }
					# format.json { render json: @appointment.errors, status: :unprocessable_entity }
          redirect_to root_path, notice: "Appointment was not created. #{@appointment.errors.first.full_message}"
				end
      end
    end
  end

	def destroy
    @appointment.destroy
    flash[:notice] = 'Appointment cancelled!'

		redirect_to patient_dashboard_path if current_user.patient?
		redirect_to doctor_dashboard_path if current_user.doctor?
  end

	def appointments_history
		@appointments = Appointment.where('schedule > ?', DateTime.now)
	end

	private

	def set_patients
		@patients = Patient.all
	end

	def set_appointment
		@appointment = Appointment.find(params[:id] || @appointment.id)
	end

	# Only allow a list of trusted parameters through.
	def appointment_params
		params.require(:appointment).permit(:user_id, :clinic_id, :schedule, :status)
	end

  def available_slots
    c =
      Clinic.all.map{|c| 
        [c.clinic_schedules.map{ |cs| 
            ( 
              x = []
              time_iterate(cs.start_time, cs.end_time, 15.minutes) do |dt|
                x << [ c.name + " " + cs.day + " " + dt.strftime("%l:%M %p") ]
              end
              if current_user.doctor? || current_user.secretary?
                x.take(15)
              else
                x
              end
            )
          }
        ] 
      }.flatten
    
    d = Date.today.beginning_of_month..Date.today.end_of_month
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
