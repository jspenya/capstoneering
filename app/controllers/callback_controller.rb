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

    if text_message_received.include? 'appointment: '
      date = text_message_received.split("\s", 2).last
      d = Date.parse(date)
      dt = DateTime.new(d.year, d.month, d.day, DateTime.now.hour, DateTime.now.min)

      Appointment.new
      response = {
        "text": "Yo!"
      }
    elsif text_message_received.include? 'name:'
      # Create the user
      password_hex = SecureRandom.hex(5)
      user, nickname, email = text_message_received.split("\s", 3)
      nickname = nickname.chomp(',')
      u = User.new(lastname: nickname, email: email, password: 'testing 123', password_confirmation: 'testing 123' )
      u.save

      response = {
        "text": "Thanks for the info, #{u.firstname}. What day would you like to set the appointment?\n\nReply in this format:\n\nex. \*appointment: April 18 2022\*"
      }
    else
      response = {
        "text": "Hi! What's your nickname & email?\n\nReply in this format:\n\n\*name: Steph, coolsteph@gmail.com\*"
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
end
