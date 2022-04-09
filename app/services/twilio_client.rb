class TwilioClient
  attr_reader :client

  def initialize
    @client = Twilio::REST::Client.new(account_sid, account_auth_token)
  end

  def send_text(user, message)
    client.api.account.messages.create(
      to: user.mobile_number,
      from: '+15005550006',
      body: message
    )
  end

  def account_sid
    'ACabea2dd43285d813c01585d49851c061'
  end

  def account_auth_token
   '608a1a16fb8104e9aa7a68ed2eee2b9d'
  end

  def phone_number
    '+63676514239'
  end
end