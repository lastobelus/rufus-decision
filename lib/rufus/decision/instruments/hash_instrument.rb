module Rufus
  module Decision
    module Instruments
      class HashInstrument
        attr_accessor :result

        def initialize
          @result = {}
        end

        def clear!
          @result.replace({})
        end

        def table_info(hash)
          @result[:table] = hash
        end
      end
    end
  end
end
