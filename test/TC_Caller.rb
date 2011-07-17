require 'test/unit'
require 'swiftcore/swiftrpc'
require 'helpers/test_support'

class TestCaller
	include Swiftcore::SwiftRPC::Caller
end

class TC_Caller < Test::Unit::TestCase
	Ruby = File.join(::Config::CONFIG['bindir'],::Config::CONFIG['ruby_install_name']) << ::Config::CONFIG['EXEEXT']
	KillQueue = []

	def setup
		cwd = File.dirname(__FILE__)
		KillQueue << SwiftcoreTestSupport::create_process(:dir => cwd, :cmd => "#{Ruby} -I#{cwd}/../lib #{cwd}/helpers/test_server.rb")
	  sleep 1
	end

	def teardown
		while p = KillQueue.pop do
			Process.kill("SIGKILL", p) if p
			Process.wait p if p
		end
	end

	def test_call
		tests_finished = {}
		EventMachine.run {
			tx = TestCaller.new
			tx.connect_to('127.0.0.1:5555','test') { tests_finished[:connected] = true }
			# Trivial request; gets back a basic object for a response.
			EM::add_timer(1) do
				tx.call_on('test', :seven) do |num|
					tests_finished[:seven] = true
					assert_equal(7,num, "The response received was not what was expected.")
				end
			end

			EM::add_timer(1) do
				tx.call_on('test', :eight) do |response|
					tests_finished[:eight] = true
					assert_equal(NoMethodError, response.class, "Expected NoMethodError, but did not get it.")
				end
			end

			EM::add_timer(1) do
				tx.call_on('test', :not_packable_array) do |response|
					tests_finished[:not_packable_array] = true
					assert_equal(Array, response.class, "The response did not return an Array.")
					assert_equal(1,response.first, "The first value in the returned response is not what was expected.")
					assert_equal(Exception, response[2].class, "The response should have contained an exception, but it appears not to.")
				end
			end
			# Trigger an exception by calling a method that does not exist; exception should propagate back to the caller.
			EM::add_timer(3) { EM.stop_event_loop }
		}
		assert tests_finished[:connected], "Did not receive affirmation that the client connected to the server."
		assert tests_finished[:seven], "The \"seven\" test did not finish."
		assert tests_finished[:eight], "The \"eight\" test did not finish."
	end

end
