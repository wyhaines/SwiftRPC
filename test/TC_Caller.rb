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
		@noderef = []
		cwd = File.dirname(__FILE__)
		ruby_cmd = "#{Ruby} -I#{cwd}/../lib"
		KillQueue << SwiftcoreTestSupport::create_process(:dir => cwd, :cmd => "#{ruby_cmd} #{cwd}/helpers/test_server.rb")
		KillQueue << SwiftcoreTestSupport::create_process(:dir => cwd, :cmd => "#{ruby_cmd} #{cwd}/helpers/test_node.rb a 1 5556")
		KillQueue << SwiftcoreTestSupport::create_process(:dir => cwd, :cmd => "#{ruby_cmd} #{cwd}/helpers/test_node.rb b 2 5557")
		KillQueue << SwiftcoreTestSupport::create_process(:dir => cwd, :cmd => "#{ruby_cmd} #{cwd}/helpers/test_node.rb c 3 5558")
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
			tx.connect_to('127.0.0.1:5555','test') { tests_finished[:connected_5555] = true }
			tx.connect_to('127.0.0.1:5556','node1') { tests_finished[:connected_5556] = true }
			tx.connect_to('127.0.0.1:5557','node2') { tests_finished[:connected_5557] = true }
			tx.connect_to('127.0.0.1:5558','node3') { tests_finished[:connected_5558] = true }

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

			EM::add_timer(1) do
				tx.call_on('node1', :ref) do |node|
					@noderef[1] = node
					node.value { |n| assert_equal("1", n, "Got the wrong value for #value from node1") }
					node.name { |n| assert_equal('a', n, "Got the wrong value for #name from node1") }
				end

				tx.call_on('node2', :ref) do |node|
					@noderef[2] = node
					node.value { |n| assert_equal("2", n, "Got the wrong value for #value from node2") }
					node.name { |n| assert_equal('b', n, "Got the wrong value for #name from node1") }
				end

				tx.call_on('node3', :ref) do |node|
					@noderef[3] = node
					node.value { |n| assert_equal("3", n, "Got the wrong value for #value from node3") }
					node.name { |n| assert_equal('c', n, "Got the wrong value for #name from node1") }
				end
			end

			EM::add_timer(1) do
				tx.on('test').seven do |num|
					tests_finished[:seven_again] = true
					assert_equal(7,num, "The response received was not what was expected.")
				end
			end

			EM::add_timer(1) do
				test = tx.on('test')
				test.seven do |num|
					tests_finished[:seven_again_too] = true
					assert_equal(7,num, "The response received was not what was expected.")
				end
			end

			EM::add_timer(2) do
				n1 = @noderef[1]
				n2 = @noderef[2]
				n1.next = n2
				@noderef[1].next = @noderef[2]
				@noderef[2].prior= @noderef[1]
				@noderef[2].next= @noderef[3]
				@noderef[3].prior= @noderef[2]
			end

			EM::add_timer(3) do
				@noderef[1].next {|n| n.next {|n| n.next {|n| puts "***** #{n.value}"}}}
			end
			# Trigger an exception by calling a method that does not exist; exception should propagate back to the caller.
			EM::add_timer(5) { EM.stop_event_loop }
		}
		assert tests_finished[:connected_5555], "Did not receive affirmation that the client connected to the general test server."
		assert tests_finished[:connected_5556], "Did not receive affirmation that the client connected to the node1 server."
		assert tests_finished[:connected_5557], "Did not receive affirmation that the client connected to the node2 server."
		assert tests_finished[:connected_5558], "Did not receive affirmation that the client connected to the node3 server."
		assert tests_finished[:seven], "The \"seven\" test did not finish."
		assert tests_finished[:seven_again], "The \"seven again\" test did not finish."
		assert tests_finished[:seven_again_too], "The \"seven again too\" test did not finish."
		assert tests_finished[:eight], "The \"eight\" test did not finish."
	end

end
