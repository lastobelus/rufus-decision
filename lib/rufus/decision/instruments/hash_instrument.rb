module Rufus
  module Decision
    module Instruments
      class HashInstrument

        attr_accessor :result

        def initialize
          @result = {}
        end

        def clear!
          @result.replace({matches: {table: false, rows: []}})
        end


        def table_info=(hash)
          @result[:table] = hash
        end

        def table_matched!
          @result[:matches][:table] = true
        end

        def row_matched!(state, index)          
          @result[:matches][:rows][index] = state
        end

      end
    end
  end
end
