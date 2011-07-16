module Swiftcore
	module SwiftRPC

		# This is the class that all blank slates are created from. The only
		#   methods that it will contain are those which are explicitly listed
		#   in the __MethodsToPreserve constant (array of symbols or strings),
		#   or those which are matched by the regular expression in
		#   __MethodPreservationRegex. You may use these properties in order to
		#   make the slate selectively less blank, if needed.
		#
		# TODO: If 1.9.x is in use, make use of BasicObject? Need to think about that.

		class BlankSlateTemplate
			@methods_to_preserve = []

			def self.__MethodsToPreserve
				@methods_to_preserve
			end

			def self.__MethodsToPreserve=(v)
				@methods_to_preserve = v
			end

			@method_preservation_regex = /^__/

			def self.__MethodPreservationRegex
				@method_preservation_regex
			end

			def self.__MethodsPreservationRegex=(v)
				@method_preservation_regex = v
			end
		end

		# Make no assumptions. If #const_missing is defined, alias it. Otherwise,
		# define a blank alias.
		if defined?(self.const_missing)
			class <<self
				alias_method :___const_missing, :const_missing
			end
		else
			def self.___const_missing(c); end
		end

		# Define our new #const_missing.
		def self.const_missing(c)
			if c == :BlankSlate
				BlankSlate()
			else
				___const_missing(c)
			end
		end

		def self.BlankSlate
			# Always preserve :object_id
			methods_to_preserve = ([:object_id] + BlankSlateTemplate::__MethodsToPreserve).collect do |v|
				v.to_s
			end

			Class.new do
				instance_methods.each do |meth|
					next if meth =~ BlankSlateTemplate::__MethodPreservationRegex
					next if methods_to_preserve.include?(meth)

					undef_method meth
				end
			end
		end

	end
end
