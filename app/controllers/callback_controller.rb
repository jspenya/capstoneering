class CallbackController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    verify_token = "asdf"

    mode = request.query_parameters['hub.mode']
    token = request.query_parameters['hub.verify_token']
    challenge = request.query_parameters['hub.challenge']

    if mode && token
      if mode == 'subscribe' && token == verify_token
        render json: challenge
      end
    else
      head 403
    end
  end

  def received_data
    request_body = request.body.read
    body = JSON.parse(request_body)

    if body.dig("object") == "page"
      body.dig('entry').each do |entry|
        webhook_event = entry.dig('messaging').first
        Rails.logger.info("Webhook event: #{webhook_event}")

        # get the sender psid
        sender_psid = webhook_event.dig('sender', 'id')
        Rails.logger.info("Sender PSID: #{sender_psid}")

        if webhook_event.dig('message').any?
          handle_message(sender_psid, webhook_event.dig('message'))
        elsif webhook_event.dig('postback').any?
          handle_postback(sender_psid, webhook_event.dig('postback'))
        end
      end
      head 200
    else
      head 403
    end
  end

  def handle_message sender_psid, received_message
    response = {}
    text_message_received = received_message.dig("text")
    # Check if message contains text

    # if text_message_received.include? 'appointment: '
    #   # d = Date.parse(date)
    #   # dt = DateTime.new(d.year, d.month, d.day, DateTime.now.hour, DateTime.now.min)
      
    #   # Appointment.new
    #   date = text_message_received.split("\s", 2).last
    #   re = Regexp.new(date, Regexp::IGNORECASE)
    #   avail_slots = available_slots.grep(re)

    #   appointment_schedule = avail_slots.first
      
    #   response = {
    #     "text": "Yo!"
    #   }
    # elsif text_message_received.include? 'name:'
    if text_message_received.include? 'BOOK:'
      byebug
      # Create the user
      password_hex = SecureRandom.hex(5)
      book, nickname, mobile_number, appointment_date = text_message_received.split("\s", 4)
      
      nickname = nickname.chomp(',')
      if mobile_number.starts_with? '0'
        mobile_number = mobile_number.delete_prefix('0').chomp(',')
      elsif mobile_number.starts_with? '+63'
        mobile_number = mobile_number.delete_prefix('+63').chomp(',')
      else
        mobile_number.chomp(',')
      end

      u = User.new(lastname: nickname, mobile_number: mobile_number, password: '123456', password_confirmation: '123456' )
      
      if u.save
        re = Regexp.new(appointment_date, Regexp::IGNORECASE)
        avail_slots = available_slots.grep(re)
        appointment_schedule = avail_slots.first
        clinic, wday, time, ampm, date = appointment_schedule.split("\s", 5)
        clinic_id = Clinic.find_by(name: clinic).id
        dt = DateTime.parse(date + " " + time + " " + ampm)

        @appointment = u.appointments.new(
          schedule: dt,
          clinic_id: clinic_id
        )

        if @appointment.save
          response = {
            "text": "You have successfully booked an appointment for: #{@appointment.schedule.strftime("%B %d, %A")}. See you then!"
          }
        else
          response = {
            "text": "There was an error in booking the appointment. Please try again."
          }
        end
      else
        response = {
          "text": "There was an error in registering user. Please try again."
        }
      end
    else
      response = {
        "text": "Hi! To book an appointment or check for an opening, send a message with your nickname, your contact number, and the date you want to book the appointment. See example below:\n\nexample:\n\n\*BOOK: Steph, 09361234567, January 20 2022\*"
      }
    end
    # Sends the response message
    call_send_api(sender_psid, response)
  end

  def handle_postback sender_psid, received_postback
  end

  def call_send_api sender_psid, response
    request_body = {
      "recipient": {
        "id": sender_psid
      },
      "message": response
    }

    puts HTTP.post(url, json: request_body)
  end

  def url
    "https://graph.facebook.com/v12.0/me/messages?access_token=#{page_access_token}"
  end

  private

  def page_access_token
    "EAADZA3dkwy1sBACyVeKF70n1leMCMEBXnZBh1qyaBQ3LmcmoYfKxapDdRqpEwIGGFAC9urIn73dnWxfliDoEpwHpZBkkBtrUyBuqoR2VqfZBm33NvqR3B6lgZARruVmjpX1LFOvfYJ0czqiLFSIsOslsil8z1jwJC0oJ0EmXsbV0j25RhZATzipFm6MBmZADnMZD"
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
