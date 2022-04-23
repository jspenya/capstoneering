class Doctors::AppointmentsController < DoctorsController
	before_action :authenticate_user!
  before_action :set_clinic, only: :index
  # before_action :set_appointments
  # before_action :set_appointment, except: :index

	def index
    @appointments_upcoming_today = @clinic&.appointments&.upcoming_appointments_today&.order(:schedule)
		@appointments = Appointment.where(cancelled: false)
	end

  def edit
    @appointment = Appointment.find(params[:id])
  end

  def filter_appointments
    appointments_sched = params[:appointment_sched]

    if appointments_sched == 'today'
      @appointments = Appointment.doctor_appointments_today.where(cancelled: false)
    elsif appointments_sched == 'all'
      @appointments = Appointment.where(cancelled: false)
    elsif appointments_sched == 'week'
      @appointments = Appointment.current_week.where(cancelled: false)
    elsif appointments_sched == 'month'
      @appointments = Appointment.current_month.where(cancelled: false)
    else
    end
  end

  def cancel_appointment
    @appointment = Appointment.find(params[:id])

    @appointment.cancelled = true

    if @appointment.save
      redirect_to doctor_appointments_url, notice: 'Appointment was successfully cancelled.'
    else
      redirect_to doctor_appointments_url, alert: "#{@appointment.errors.first.full_message}"
    end
  end

  def update
    @appointment = Appointment.find(params[:id])
    
    if @appointment.update(appointment_params)
      redirect_to doctor_appointments_url, notice: 'Appointment was successfully cancelled.'
    else
      redirect_to doctor_appointments_url, alert: "#{@appointment.errors.first.full_message}"
    end
  end

  def reschedule_appointment
    @appointment = Appointment.find(params[:id])
    
    app_sched = params[:appointment][:appointment_schedule]
    clinic, wday, time, ampm, date = app_sched.split("\s",5)
    clinic_id = Clinic.find_by(name: clinic).id
    dt = DateTime.parse(date + " " + time + " " + ampm)

    @appointment.schedule = dt
    @appointment.clinic_id = clinic_id

    if @appointment.save
      redirect_to doctor_appointments_url, notice: "Appointment updated successfully!"
    else
      redirect_to doctor_appointments_url, alert: " #{@appointment.errors.first.full_message}"
    end
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
	
	private

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
                  x.take(cs.slots)
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
	
	def set_appointments
		@appointments_upcoming_today = @clinic&.appointments&.upcoming_appointments_today&.order(:schedule)
		@appointments = @clinic&.appointments&.doctor_appointments_today&.order(:schedule)
	end

	def set_appointment
		@appointment = Appointment.find(params[:id])
	end

	def set_clinic
		clinic_id = ClinicSchedule.where(day: Date.today.strftime("%A"))&.first&.clinic_id
		
		@clinic = Clinic.find(clinic_id) if clinic_id.present?
	end

  def set_patient
  end

  def appointment_params
    params.require(:appointment).permit(:user_id, :schedule, :clinic_id, :slots, :status)
  end
end
