require 'sidekiq-scheduler'

class HardJob
  include Sidekiq::Worker

  def perform(*args)
    logger.info "Hello, world!"
  end

  def logger
    @logger ||= Logger.new('log/sidekiq-scheduler-test.log')
  end
end
