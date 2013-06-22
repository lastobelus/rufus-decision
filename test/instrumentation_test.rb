require File.expand_path('../base.rb', __FILE__)

require "rufus/decision/instruments/hash_instrument"
module InstrumentationTestMixin

  protected
  def do_instrumented_test(table_data, h, expected_result, verbose=false)
    table = instrumented_table(table_data)
    do_test(table, h, expected_result, verbose=false)
    table
  end

  def assert_instrumentation(table, expected)
    assert_equal( expected, table.instrument.result, "instrumentation result should match expected")
  end

  def default_table_options
    {:first_match => true, :ignore_case => nil, :unbounded => nil}
  end

  def instrumented_table(table_data)
    table =
      if table_data.is_a?(Rufus::Decision::Table)
        table_data
      else
        Rufus::Decision::Table.new(table_data)
      end

    table.instrument = Rufus::Decision::Instruments::HashInstrument.new
    table
  end

  def do_instrumented_transform(table_data, in_h)
    table = instrumented_table(table_data)
    table.transform!(in_h)
    table
  end
end

class InstrumentationTest < Test::Unit::TestCase
  class MockInstrument
    attr_accessor :result
    def initialize
      @result = 'old_data'
    end

    def method_missing(meth, *args, &block)
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

    CSV1 = %{
    accumulate,,
    in:fx,in:fy,out:fz
    ,,
    a,b,0
    c,d,1
    e,f,2
    c,d,7
  }

  def test_instrument_cleared_each_run
    table = Rufus::Decision::Table.new(CSV0)
    table.instrument = MockInstrument.new
    table.transform!({"fx" => "c", "fy" => "d"})
    assert_equal('new_data', table.instrument.result, "calling transform should clear instrument")
  end

  def test_sets_table_info
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result, "instrument result")
    assert_not_nil(table.instrument.result[:table], "instrument result :table")    
  end

  def test_sets_matches_table
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result[:matches], "instrument result :matches")    
    assert_not_nil(table.instrument.result[:matches][:table], "instrument result :matches :table")    
    assert(table.instrument.result[:matches][:table], "instrument result :matches :table true")

    table.transform!({"fx" => "c", "fy" => "e"})
    assert_not_nil(table.instrument.result[:matches], "instrument result :matches")    
    assert_not_nil(table.instrument.result[:matches][:table], "instrument result :matches :table")    
    refute(table.instrument.result[:matches][:table], "instrument result :matches :table false")    
  end


  def test_sets_matches_rows
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result[:matches][:rows], 
      "instrument result :matches :rows exists")    
    assert_equal( [false, true],
                  table.instrument.result[:matches][:rows], 
                  "instrument result :matches :table :rows is correct")

    table.transform!({"fx" => "c", "fy" => "e"})
    assert_not_nil(table.instrument.result[:matches][:rows], 
      "instrument result :matches :table exists")    
    assert_equal( [false, false, false],
                  table.instrument.result[:matches][:rows], 
                  "instrument result :matches :table :rows is correct")
  end

  def test_sets_matches_cells
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result[:matches][:cells], 
      "instrument result :matches :cells exists")    
    assert_equal( [[false], [true, true]],
                  table.instrument.result[:matches][:cells], 
                  "instrument result :matches :table :cells is correct")

    table.transform!({"fx" => "c", "fy" => "e"})
    assert_not_nil(table.instrument.result[:matches][:cells], 
      "instrument result :matches :table exists")    
    assert_equal( [[false], [true, false], [false]],
                  table.instrument.result[:matches][:cells], 
                  "instrument result :matches :table :cells is correct")
  end

  def test_sets_num_matches
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_equal(1, table.instrument.result[:matches][:num],
      "instrument result :matches :num is correct")

    table = do_instrumented_transform(CSV1, {"fx" => "c", "fy" => "d"})
    assert_equal(2, table.instrument.result[:matches][:num],
      "instrument result :matches :num is correct")
  end

  def test_sets_applies
    table = do_instrumented_transform(CSV0, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result[:matches][:applies])
    assert_equal(2, table.instrument.result[:matches][:applies].length)
    table = do_instrumented_transform(CSV1, {"fx" => "c", "fy" => "d"})
    assert_not_nil(table.instrument.result[:matches][:applies])
    assert_equal(4, table.instrument.result[:matches][:applies].length)
  end

  def test_1_without_accumulate

    wi = {
      "fx" => "c",
      "fy" => "d"
    }
    table = do_instrumented_test(CSV0, wi, { "fz" => "1" }, false)
    assert_instrumentation(
      table,
      :table => { :rows => 3, :ins => 2, :outs => 1, :options => default_table_options },
      :matches => {
        :table => true,
        :rows => [false, true],
        :num => 1,
        :cells => [
          [false],
          [true, true],
        ],
        :applies => [
          nil,
          {2 => {:old_value => nil, :new_value => "1", :name => 'fz'}}
        ]
      }
    )
  end

  def test_2_without_accumulate

    wi = {
      "fx" => "a",
      "fy" => "d"
    }
    table = do_instrumented_test(CSV0, wi, { "fz" => nil }, false)
    assert_instrumentation(
      table,
      :table => { :rows => 3, :ins => 2, :outs => 1, :options => default_table_options  },
      :matches => {
        :table => false,
        :rows => [false, false, false],
        :num => 0,
        :cells => [
          [true, false],
          [false],
          [false]
        ],
      }
    )


  end


  def test_3_with_accumulate

    wi = {
      "fx" => "c",
      "fy" => "d"
    }
    table = do_instrumented_test(CSV1, wi, { "fz" => "1;7" }, false)
    assert_instrumentation(
      table,
      :table => { :rows => 4, :ins => 2, :outs => 1, 
        :options => default_table_options.merge(:accumulate => true, :first_match => false) },
      :matches => {
        :table => true,
        :rows => [false, true, false, true],
        :num => 2,
        :cells => [
          [false],
          [true, true],
          [false],
          [true, true]
        ],
        :applies => [
          nil,
          {2=>{:name=>"fz", :new_value=>"1", :old_value=>nil}},
          nil,
          {2=>{:name=>"fz", :new_value=>["1", "7"], :old_value=>"1"}}
        ]
      }
    )

  end


end