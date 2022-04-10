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

    if text_message_received
      # Create the payload for a basic text message
      response = {
        "text": "You send the message #{text_message_received}. Now send me an image!"
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
    "EAADZA3dkwy1sBAMFOgHG2YADC5gc8u3LVK0Y46qnH5davokVMP6mwReut6RZBmhvuUS1Tgygqi0xn2sEZClMvOdBRxmZBRMbtvZBot67mcGFWNV71fbxP6etN30xXjVa26vO2g28lPcIZCwWhUBZAsiYfbxHFQROsPdLoI7D8zTv4S63S7HdeIGoAlYOaeRpZAAZD"
  end
end
