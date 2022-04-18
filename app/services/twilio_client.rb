class TwilioClient
  attr_reader :client

  def initialize
    @client = Twilio::REST::Client.new(account_sid, account_auth_token)
  end

  def send_text(user, message)
    client.api.account.messages.create(
      to: "+63" + user.mobile_number,
      from: '(254) 347-2656',
      body: message
    )
  end

  def account_sid
    Rails.application.credentials.twilio[:account_sid]
  end
  
  def account_auth_token
    Rails.application.credentials.twilio[:auth_token]
  end
end
