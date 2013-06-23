
#
# testing accumulate & accumulate-new options
#

require File.expand_path('../base.rb', __FILE__)

class Dt6Test < Test::Unit::TestCase
  include DecisionTestMixin

  NO_DUPES = %{
    ,,
    in:fx,in:fy,out:fz
    ,,
    a,b,0
    c,d,1
    e,f,2
  }

  DUPES = %{
    ,,
    in:fx,in:fy,out:fz,out:fk
    ,,
    a,b,0,m
    c,d,1,n
    a,b,2,o
    e,f,3,p
    a,b,4,q
  }

  DUPES_AND_BLANKS = %{
    ,,
    in:fx,in:fy,out:fz,out:fm
    ,,
    a,b,0,
    c,d,1,2
    a,b,,3
    e,f,4,5
    a,b,6,7
  }

  # Current Behaviour

  def test_accumulate_without_dupes_or_existing_value_is_noop

    table = Rufus::Decision::Table.new(NO_DUPES, :accumulate => true)
    wi = {
      "fx" => "a",
      "fy" => "b"
    }
    do_test(table, wi, { "fz" => "0" }, false)
  end

  def test_accumulate_without_dupes_includes_existing_value

    table = Rufus::Decision::Table.new(NO_DUPES, :accumulate => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
      "fz" => 'k'
    }
    do_test(table, wi, { "fz" => "k;0" }, false)
  end

  def test_accumulate_with_dupes_includes_existing_value

    table = Rufus::Decision::Table.new(DUPES, :accumulate => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
      "fz" => 'k'
    }

    # This demonstrates the "alignment" problem with existing accumulate option
    do_test(table, wi, { "fz" => "k;0;2;4", "fk" => "m;o;q" }, false)
  end

  def test_accumulate_ignores_blanks

    table = Rufus::Decision::Table.new(DUPES_AND_BLANKS, :accumulate => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
    }

    # This demonstrates another "alignment" problem with existing accumulate option
    do_test(table, wi, { "fz" => "0;6", "fm" => "3;7" }, false)
  end



# Proposed accumulate-all option

  def test_accumulate_all_without_dupes_or_existing_value_is_noop
    table = Rufus::Decision::Table.new(NO_DUPES, :accumulate_all => true)
    wi = {
      "fx" => "a",
      "fy" => "b"
    }
    do_test(table, wi, { "fz" => "0" }, false)
  end

  def test_accumulate_all_without_dupes_overwrites_existing_value
    table = Rufus::Decision::Table.new(NO_DUPES, :accumulate_all => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
      "fz" => 'k'
    }
    do_test(table, wi, { "fz" => "0" }, false)
  end

  def test_accumulate_all_with_dupes_overwrites_existing_value

    table = Rufus::Decision::Table.new(DUPES, :accumulate_all => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
      "fz" => 'k'
    }

    # This demonstrates correct "alignment" with accumulate-all option
    do_test(table, wi, { "fz" => "0;2;4", "fk" => "m;o;q" }, false)
  end

  def test_accumulate_all_includes_blanks

    table = Rufus::Decision::Table.new(DUPES_AND_BLANKS, :accumulate_all => true)
    wi = {
      "fx" => "a",
      "fy" => "b",
    }

    # This demonstrates correct "alignment" with accumulate-all option
    do_test(table, wi, { "fz" => "0;;6", "fm" => ";3;7" }, false)
  end

end
