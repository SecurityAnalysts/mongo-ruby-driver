COVERAGE_MIN = 90
CURRENT_PATH = File.expand_path(File.dirname(__FILE__))
SERVER_DISCOVERY_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/sdam/**/*.yml")
SDAM_MONITORING_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/sdam_monitoring/*.yml")
SERVER_SELECTION_RTT_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/server_selection_rtt/*.yml")
SERVER_SELECTION_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/server_selection/**/*.yml")
MAX_STALENESS_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/max_staleness/**/*.yml")
CRUD_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/crud/**/*.yml")
RETRYABLE_WRITES_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/retryable_writes/**/*.yml")
COMMAND_MONITORING_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/command_monitoring/**/*.yml")
CONNECTION_STRING_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/connection_string/*.yml")
DNS_SEEDLIST_DISCOVERY_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/dns_seedlist_discovery/*.yml")
GRIDFS_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/gridfs/*.yml")
TRANSACTIONS_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/transactions/*.yml")
CHANGE_STREAMS_TESTS = Dir.glob("#{CURRENT_PATH}/spec_tests/data/change_streams/*.yml")

if ENV['DRIVERS_TOOLS']
  CLIENT_CERT_PEM = ENV['DRIVER_TOOLS_CLIENT_CERT_PEM']
  CLIENT_KEY_PEM = ENV['DRIVER_TOOLS_CLIENT_KEY_PEM']
  CA_PEM = ENV['DRIVER_TOOLS_CA_PEM']
  CLIENT_KEY_ENCRYPTED_PEM = ENV['DRIVER_TOOLS_CLIENT_KEY_ENCRYPTED_PEM']
else
  SSL_CERTS_DIR = "#{CURRENT_PATH}/support/certificates"
  CLIENT_PEM = "#{SSL_CERTS_DIR}/client.pem"
  CLIENT_PASSWORD_PEM = "#{SSL_CERTS_DIR}/password_protected.pem"
  CA_PEM = "#{SSL_CERTS_DIR}/ca.pem"
  CRL_PEM = "#{SSL_CERTS_DIR}/crl.pem"
  CLIENT_KEY_PEM = "#{SSL_CERTS_DIR}/client_key.pem"
  CLIENT_CERT_PEM = "#{SSL_CERTS_DIR}/client_cert.pem"
  CLIENT_KEY_ENCRYPTED_PEM = "#{SSL_CERTS_DIR}/client_key_encrypted.pem"
  CLIENT_KEY_PASSPHRASE = "passphrase"
end

require 'mongo'

unless ENV['CI']
  begin
    require 'byebug'
  rescue LoadError
    # jruby - try pry
    begin
      require 'pry'
    # jruby likes to raise random error classes, in this case
    # NameError in addition to LoadError
    rescue Exception
    end
  end
end

require 'support/spec_config'

Mongo::Logger.logger = Logger.new($stdout)
unless SpecConfig.instance.client_debug?
  Mongo::Logger.logger.level = Logger::INFO
end
Encoding.default_external = Encoding::UTF_8

require 'ice_nine'
require 'support/matchers'
require 'support/lite_constraints'
require 'support/event_subscriber'
require 'support/server_discovery_and_monitoring'
require 'support/server_selection_rtt'
require 'support/server_selection'
require 'support/sdam_monitoring'
require 'support/crud'
require 'support/command_monitoring'
require 'support/connection_string'
require 'support/gridfs'
require 'support/transactions'
require 'support/change_streams'
require 'support/common_shortcuts'
require 'support/client_registry'
require 'support/client_registry_macros'

if SpecConfig.instance.mri?
  require 'timeout_interrupt'
else
  require 'timeout'
  TimeoutInterrupt = Timeout
end

RSpec.configure do |config|
  if ENV['CI'] && SpecConfig.instance.jruby?
    config.formatter = 'documentation'
  end

  config.extend(CommonShortcuts)
  config.extend(LiteConstraints)
  config.include(ClientRegistryMacros)

  if SpecConfig.instance.ci?
    config.add_formatter(RSpec::Core::Formatters::JsonFormatter, File.join(File.dirname(__FILE__), '../tmp/rspec.json'))
  end

  if SpecConfig.instance.ci?
    # Allow a max of 30 seconds per test.
    # Tests should take under 10 seconds ideally but it seems
    # we have some that run for more than 10 seconds in CI.
    config.around(:each) do |example|
      TimeoutInterrupt.timeout(45) do
        example.run
      end
    end
  end
end

EventSubscriber.initialize
