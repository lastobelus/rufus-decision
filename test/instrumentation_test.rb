require File.expand_path('../base.rb', __FILE__)

require "rufus/decision/instruments/hash_instrument"
module InstrumentationTestMixin

  protected
  def do_instrumented_test(table_data, h, expected_result, verbose=false)
    table =
      if table_data.is_a?(Rufus::Decision::Table)
        table_data
      else
        Rufus::Decision::Table.new(table_data)
      end

    table.instrument = Rufus::Decision::Instruments::HashInstrument.new
    do_test(table, h, expected_result, verbose=false)
    table
  end

  def assert_instrumentation(table, expected)
    assert_equal( expected, table.instrument.result, "instrumentation result should match expected")
  end
end

class InstrumentationTest < Test::Unit::TestCase
  class MockInstrument
    attr_accessor :result
    def initialize
      @result = 'old_data'
    end

    def method_missing
      nil
    end

    def clear!
      @result = 'new_data'
    end
  end

  include DecisionTestMixin
  include InstrumentationTestMixin
    CSV0 = %{
    ,,
    in:fx,in:fy,out:fz
    ,,
    a,b,0
    c,d,1
    e,f,2
  }

  def test_instrument_cleared_each_run
    table = Rufus::Decision::Table.new(CSV0)
    table.instrument = MockInstrument.new
    table.transform!("fx" => "c", "fy" => "d")
    assert_equal('new_data', table.instrument.result, "calling transform should clear instrument")
  end


  def test_without_accumulate

    wi = {
      "fx" => "c",
      "fy" => "d"
    }
    table = do_instrumented_test(CSV0, wi, { "fz" => "1" }, false)
    assert_instrumentation(
      table,
      table: { rows: 3, ins: 2, outs: 1, options: [] },
      matches: {
        table: true,
        num: 1,
        rows: [false, true],
        cells: [
          [false, false],
          [true, true],
        ]
      }
    )

    wi = {
      "fx" => "a",
      "fy" => "d"
    }
    do_instrumented_test(CSV0, wi, { "fz" => nil }, false)
    assert_instrumentation(
      table,
      table: { rows: 3, ins: 2, outs: 1, options: []  },
      matches: {
        table: false,
        rows: [false, false, false],
        cells: [
          [true, false],
          [false, true],
          [false, false]
        ]
      }
    )


  end



end