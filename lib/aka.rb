require "aka/version"

module Aka
  class Base < Thor

      desc 'demo', 'To test out Thor'
      def show()
        puts "Demo success"
      end
    end
end
