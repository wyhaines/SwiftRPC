require 'test/unit'
require 'swiftcore/swiftrpc/blankslate'

module Swiftcore
  module SwiftRPC
    MISSING_CONSTANTS = []
    def self.___const_missing(c)
      MISSING_CONSTANTS << c
      nil
    end
  end
end

class TC_BlankSlate < Test::Unit::TestCase

	def test_blankslate
		# Verify that const_missing is working as expected
    Swiftcore::SwiftRPC::A
    Swiftcore::SwiftRPC::B
    Swiftcore::SwiftRPC::C

    assert_equal [:A, :B, :C], Swiftcore::SwiftRPC::MISSING_CONSTANTS,
      "The collected missing constants did not match what was expected."

    Swiftcore::SwiftRPC::BlankSlateTemplate.__MethodsToPreserve << 'respond_to?'

		# Create a BlankSlate instance

    blankslate = Swiftcore::SwiftRPC::BlankSlate

    methods_to_preserve = ([:object_id] + Swiftcore::SwiftRPC::BlankSlateTemplate::__MethodsToPreserve).collect do |v|
      v.to_s
    end

    Swiftcore::SwiftRPC::BlankSlateTemplate.methods.each do |meth|
      next if meth =~ Swiftcore::SwiftRPC::BlankSlateTemplate::__MethodPreservationRegex
      next if methods_to_preserve.include?(meth)

      assert blankslate.respond_to?(meth), "Blankslate responded to #{meth}, but should not have."
    end

    blankslate2 = Swiftcore::SwiftRPC::BlankSlate
    assert_not_equal(blankslate, blankslate2, "Each BlankSlate should be unique.")
	end
end
