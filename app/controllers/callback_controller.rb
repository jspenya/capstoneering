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

  def get_user_profile
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

  def post_user_profile
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

    if text_message_received.include? 'NEW_PATIENT,'
      # Create the user
      password_hex = SecureRandom.hex(5)
      book, nickname, mobile_number, appointment_date = text_message_received.split(', ', 4)

      if book.present? && nickname.present? && mobile_number.present? && appointment_date.present?
        nickname = nickname.chomp(',')
        if mobile_number.starts_with? '0'
          mobile_number = mobile_number.delete_prefix('0').chomp(',')
        elsif mobile_number.starts_with? '+63'
          mobile_number = mobile_number.delete_prefix('+63').chomp(',')
        else
          mobile_number.chomp(',')
        end

        re = Regexp.new(appointment_date, Regexp::IGNORECASE)
        avail_slots = available_slots.map{|s| s.gsub(/ +/, " ")}.grep(re)
        if avail_slots.any?
          appointment_schedule = avail_slots.first
          clinic, wday, time, ampm, date = appointment_schedule.split("\s", 5)
          clinic_id = Clinic.find_by(name: clinic).id
          dt = DateTime.parse(date + " " + time + " " + ampm)

          u = User.new(lastname: nickname, mobile_number: mobile_number, password: '123456', password_confirmation: '123456' )

          if dt > DateTime.now
            if u.save
              @appointment = u.appointments.new(
                schedule: dt,
                clinic_id: clinic_id
              )

              if @appointment.save
                response = {
                  "text": "You have successfully booked an appointment for: #{@appointment.schedule.strftime("%B %d, %A")} at #{@appointment.schedule.strftime("%I:%M %p")}. You can also now login to your WEBDASS account here: https://webdass-staging.herokuapp.com using your Mobile Number and the default password '123456' (Please change this upon logging in). Your Account Reference Code is #{u.facebook_key}. This is used for booking appointments here in this portal.\n\nDO NOT SHARE this information with anyone else.\n\nThank you and be safe!"
                }
              else
                response = {
                  "text": "#{@appointment.errors.first.full_message}. Please try again."
                }
              end
            else
              response = {
                "text": "#{u.errors.first.full_message}. Please try again."
              }
            end
          else
            response = {
              "text": "You cannot book an appointment in the past. Please check and try again!"
            }
          end
        else
          response = {
            "text": "Sorry, you cannot book an appointment on that day. Please try again."
          }
        end
      else
        response = {
          "text": "Sorry! Your response is missing some of the required fields. Please check and try again."
        }
      end
    elsif text_message_received.include? 'EXISTING_PATIENT'
      book, nickname, mobile_number, fb_key, appointment_date = text_message_received.split(', ', 5)

      if book.present? && nickname.present? && mobile_number.present? && fb_key.present? && appointment_date.present?

        nickname = nickname.chomp(',')

        if mobile_number.starts_with? '0'
          mobile_number = mobile_number.delete_prefix('0').chomp(',')
        elsif mobile_number.starts_with? '+63'
          mobile_number = mobile_number.delete_prefix('+63').chomp(',')
        else
          mobile_number.chomp(',')
        end

        re = Regexp.new(appointment_date, Regexp::IGNORECASE)
        avail_slots = available_slots.map{|s| s.gsub(/ +/, " ")}.grep(re)
        if avail_slots.any?
          appointment_schedule = avail_slots.first
          clinic, wday, time, ampm, date = appointment_schedule.split("\s", 5)
          clinic_id = Clinic.find_by(name: clinic).id
          dt = DateTime.parse(date + " " + time + " " + ampm)

          u = User.find_by(mobile_number: mobile_number)

          if dt > DateTime.now
            if u.present?
              if u.facebook_key == fb_key
                @appointment = u.appointments.new(
                  schedule: dt,
                  clinic_id: clinic_id
                )

                if @appointment.save
                  response = {
                    "text": "You have successfully booked an appointment for: #{@appointment.schedule.strftime("%B %d, %A")} at #{@appointment.schedule.strftime("%I:%M %p")}. You can also now login to your WEBDASS account here:https://webdass-staging.herokuapp.com using your Mobile Number and the default password '123456' (Please change this upon logging in). Your Account Reference Code is #{u.facebook_key}. This is used for booking appointments here in this portal.\n\nDO NOT SHARE this information with anyone else.\n\nThank you and be safe!"
                  }
                else
                  response = {
                    "text": "#{@appointment.errors.first.full_message} Please try again."
                  }
                end
              else
                response = {
                  "text": "Your Account Reference code from your account doesn't match. Please try again."
                }
              end
            else
              response = {
                "text": "User record doesn't exist. Please try again."
              }
            end
          end
        else
          response = {
            "text": "Sorry, you cannot book an appointment on that day. Please try again."
          }
        end
      else
        response = {
          "text": "Sorry! Your response is missing some of the required fields. Please check and try again."
        }
      end
    elsif text_message_received.include? 'CL-'
      clinic_w_id = text_message_received.split("\s", 2).first
      clinic_id = clinic_w_id.split('-').last
      clinic = Clinic.find(clinic_id)

      clinic_schedules = clinic.clinic_schedules
      scheds = []
      clinic_schedules.each do |cs|
        scheds << "- Every " + cs.day + " from " + cs.start_time.strftime("%I:%M %p") + " to " + cs.end_time.strftime("%I:%M %p") + "\n"
      end

      response = {
        "text": "Clinic Schedules for #{clinic.name.split('_').join(' ')}:\n\n#{scheds.join('')}\nDisclaimer: Please note that these schedules are subject to change due availability of the doctor.\n\nTo book your appointment, send us a message with your lastname, contact number, and the date of your appointment.\n\n-------\n\nIf this is your first time to book an appointment here, type:\nNEW_PATIENT, [LASTNAME], [MOBILENUMBER], [MONTH_OF_APPOINTMENT] [DAY_OF_APPOINTMENT] [YEAR_OF_APPOINTMENT]\n\nIf you have an existing account in WEBDASS, follow the example:\nEXISTING_PATIENT, Dela Cruz, 09362565221, [ACCOUNT_REFERENCE_CODE], September 27, 2022\n\nNOTE: Your Account Reference Code was sent to you when your account was created."
      }
    else
      clinics = []
      Clinic.all.each do |c|
        # clinics =[]
        clinics << "CL-" + c.id.to_s + " " + c.name.split('_').join(' ') + "\n"
      end
      response = {
        "text": "Hi there! Welcome to the WEBDASS Appointments Booking Portal. To proceed with your booking, please choose a clinic:\n\n#{clinics.join('')}\n\nTo check for the clinic schedules,\nreply with the clinic ID.\n\nExample:\nCL-1"
      }
    end
    # Sends the response message
    call_send_api(sender_psid, response)
    rescue ActiveRecord::RecordNotFound
      response = {
        "text": "Sorry! We don't seem to have that record. Please check if you have typed that correctly and try again."
      }
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
              if special_case = cs.clinic_special_cases.find_by(day: Date.today)
                x.take(special_case.slots)
              else
                x.take(cs.slots)
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
