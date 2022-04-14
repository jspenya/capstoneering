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
      password: password_hex,
      password_confirmation: password_hex,
    )

    if @patient.save
      user = User.find(@patient.id)
      app_sched = params[:appointment_schedule]

      clinic, wday, time, ampm, date = app_sched.split("\s",5)
      clinic_id = Clinic.find_by(name: clinic).id
      dt = DateTime.parse(date + " " + time + " " + ampm)

      @appointment = user.appointments.new(
        schedule: dt,
        clinic_id: clinic_id
      )
      if @appointment.save
        redirect_to root_path, notice: "Appointment set successfully!"
      else
        redirect_to doctor_book_appointment_url, alert: " #{@appointment.errors.first.full_message}"
      end
    else
      redirect_to new_appointment_path, alert: "#{@patient.errors.first.full_message}"
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
              time_iterate(cs.start_time, cs.end_time, 15.minutes) do |dt|
                x << [ c.name + " " + cs.day + " " + dt.strftime("%l:%M %p") ]
              end
              if special_case = cs.clinic_special_cases.find_by(day: Date.today)
                x.take(special_case.slots)
              else
                x.take(15)
              end
            )
          }
        ]
      }.flatten

    d = Date.today.beginning_of_month..Date.today.end_of_month.next_month
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
