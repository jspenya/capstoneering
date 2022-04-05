def logger
	@logger ||= Logger.new('log/logging_test.log')
end

logger.info "Hello, world!"

