require 'factory_bot'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.disable_monkey_patching!
end
