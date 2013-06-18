module Rufus
  module Decision
    module Instruments
      class HashInstrument

        attr_accessor :result

        def initialize
          @result = {}
        end

        def clear!
          @result.replace({matches: {table: false, rows: [], cells: []}})
        end


        def table_info=(hash)
          @result[:table] = hash
        end

        def table_matched!
          @result[:matches][:table] = true
        end

        def row_matched!(state, index)          
          @result[:matches][:rows][index] = state
          @result[:matches][:num] ||= 0
          @result[:matches][:num] += 1 if state
        end

        def cell_matched!(state, row_index, cell_index)          
          @result[:matches][:cells][row_index] ||= []
          @result[:matches][:cells][row_index][cell_index] = state
        end

      end
    end
  end
end
