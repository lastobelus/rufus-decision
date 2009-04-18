#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'csv'
require 'open-uri'

require 'rubygems'
require 'rufus/dollar'

require 'rufus/hashes'


module Rufus

  # Does s starts with prefix ?
  #
  def Rufus.starts_with? (s, prefix)

    return false unless s
    (s[0, prefix.length] == prefix)
  end


  #
  # A decision table is a description of a set of rules as a CSV (comma
  # separated values) file. Such a file can be edited / generated by
  # a spreadsheet (Excel, Google spreadsheets, Gnumeric, ...)
  #
  # == Disclaimer
  #
  # The decision / CSV table system is no replacement for
  # full rule engines with forward and backward chaining, RETE implementation
  # and the like...
  #
  #
  # == Usage
  #
  # The following CSV file
  #
  #   in:topic,in:region,out:team_member
  #   sports,europe,Alice
  #   sports,,Bob
  #   finance,america,Charly
  #   finance,europe,Donald
  #   finance,,Ernest
  #   politics,asia,Fujio
  #   politics,america,Gilbert
  #   politics,,Henry
  #   ,,Zach
  #
  # embodies a rule for distributing items (piece of news) labelled with a
  # topic and a region to various members of a team.
  # For example, all news about finance from Europe are to be routed to
  # Donald.
  #
  # Evaluation occurs row by row. The "in out" row states which field
  # is considered at input and which are to be modified if the "ins" do
  # match.
  #
  # The default behaviour is to change the value of the "outs" if all the
  # "ins" match and then terminate.
  # An empty "in" cell means "matches any".
  #
  # Enough words, some code :
  #
  #   table = DecisionTable.new("""
  #     in:topic,in:region,out:team_member
  #     sports,europe,Alice
  #     sports,,Bob
  #     finance,america,Charly
  #     finance,europe,Donald
  #     finance,,Ernest
  #     politics,asia,Fujio
  #     politics,america,Gilbert
  #     politics,,Henry
  #     ,,Zach
  #   """)
  #
  #   h = {}
  #   h["topic"] = "politics"
  #
  #   table.transform! h
  #
  #   puts h["team_member"]
  #     # will yield "Henry" who takes care of all the politics stuff,
  #     # except for Asia and America
  #
  # '>', '>=', '<' and '<=' can be put in front of individual cell values :
  #
  #   table = DecisionTable.new("""
  #     ,
  #     in:fx, out:fy
  #     ,
  #     >100,a
  #     >=10,b
  #     ,c
  #   """)
  #
  #   h = { 'fx' => '10' }
  #   table.transform! h
  #
  #   require 'pp'; pp h
  #     # will yield { 'fx' => '10', 'fy' => 'b' }
  #
  # Such comparisons are done after the elements are transformed to float
  # numbers. By default, non-numeric arguments will get compared as Strings.
  #
  #
  # == transform and transform!
  #
  # The method transform! acts directly on its parameter hash, the method
  # transform will act on a copy of it. Both methods return their transformed
  # hash.
  #
  #
  # == Ruby ranges
  #
  # Ruby ranges are also accepted in cells.
  #
  #   in:f0,out:result
  #   ,
  #   0..32,low
  #   33..66,medium
  #   67..100,high
  #
  # will set the field 'result' to 'low' for f0 => 24
  #
  #
  # == Options
  #
  # You can put options on their own in a cell BEFORE the line containing
  # "in:xxx" and "out:yyy" (ins and outs).
  #
  # Currently, two options are supported, "ignorecase" and "through".
  #
  # * "ignorecase", if found by the DecisionTable will make any match (in the
  #   "in" columns) case unsensitive.
  #
  # * "through", will make sure that EVERY row is evaluated and potentially
  #   applied. The default behaviour (without "through"), is to stop the
  #   evaluation after applying the results of the first matching row.
  #
  # * "accumulate", behaves as with "through" set but instead of overriding
  #   values each time a match is found, will gather them in an array.
  #
  #   accumulate
  #   in:f0,out:result
  #   ,
  #   ,normal
  #   >10,large
  #   >100,xl
  #
  #   will yield { result => [ 'normal', 'large' ]} for f0 => 56
  #
  #
  # == Cross references
  #
  # By using the 'dollar notation', it's possible to reference a value
  # already in the hash.
  #
  #   in:value,in:roundup,out:newvalue
  #   0..32,true,32
  #   33..65,true,65
  #   66..99,true,99
  #   ,,${value}
  #
  # Here, if 'roundup' is set to true, newvalue will hold 32, 65 or 99
  # as value, else it will simply hold the 'value'.
  #
  # The value is the value as currently found in the transformed hash, not
  # as found in the original (non-transformed) hash.
  #
  #
  # == Ruby code evaluation
  #
  # The dollar notation can be used for yet another trick, evaluation of
  # ruby code at transform time.
  #
  # Note though that this feature is only enabled via the :ruby_eval
  # option of the transform!() method.
  #
  #   decisionTable.transform! h, :ruby_eval => true
  #
  # That decision table may look like :
  #
  #   in:value,in:result
  #   0..32,${r:Time.now.to_f}
  #   33..65,${r:call_that_other_function()}
  #   66..99,${r:${value} * 3}
  #
  # (It's a very simplistic example, but I hope it demonstrates the
  # capabilities of this technique)
  #
  #
  # == See also
  #
  # * http://jmettraux.wordpress.com/2007/02/11/ruby-decision-tables/
  #
  class DecisionTable

    #
    # when set to true, the transformation process stops after the
    # first match got applied.
    #
    attr_accessor :first_match

    #
    # when set to true, matches evaluation ignores case.
    #
    attr_accessor :ignore_case

    #
    # when set to true, multiple matches result get accumulated in
    # an array.
    #
    attr_accessor :accumulate

    #
    # The constructor for DecisionTable, you can pass a String, an Array
    # (of arrays), a File object. The CSV parser coming with Ruby will take
    # care of it and a DecisionTable instance will be built.
    #
    def initialize (csv_data)

      @first_match = true
      @ignore_case = false
      @accumulate = false

      @header = nil
      @rows = []

      csv_array = to_csv_array(csv_data)

      csv_array.each do |row|

        next if empty_row?(row)

        if @header

          @rows << row.collect { |c| c.strip if c }
        else

          parse_header_row(row)
        end
      end
    end

    #
    # Like transform, but the original hash doesn't get touched,
    # a copy of it gets transformed and finally returned.
    #
    def transform (hash, options={})

      transform!(hash.dup, options)
    end

    #
    # Passes the hash through the decision table and returns it,
    # transformed.
    #
    def transform! (hash, options={})

      hash = Rufus::EvalHashFilter.new(hash) \
        if options[:ruby_eval] == true

      @rows.each do |row|

        if matches?(row, hash)

          apply row, hash
          break if @first_match
        end
      end

      hash
    end

    #
    # Outputs back this table as a CSV String
    #
    def to_csv

      s = ''
      s << @header.to_csv
      s << "\n"
      @rows.each do |row|
        s << row.join(",")
        s << "\n"
      end
      s
    end

    private

      def parse_uri (string)

        return nil if string.split("\n").size > 1

        URI::parse(string) rescue nil
      end

      def to_csv_array (csv_data)

        return csv_data if csv_data.kind_of?(Array)

        csv_data = csv_data.to_s if csv_data.is_a?(URI)

        csv_data = open(csv_data) if parse_uri(csv_data)

        CSV::Reader.parse(csv_data)
      end

      def matches? (row, hash)

        return false if empty_row?(row)

        #puts
        #puts "__row match ?"
        #p row

        @header.ins.each_with_index do |in_header, icol|

          in_header = resolve_in_header(in_header)

          value = Rufus::dsub in_header, hash

          cell = row[icol]

          next if not cell

          cell = cell.strip

          next if cell.length < 1

          cell = Rufus::dsub cell, hash

          #puts "__does '#{value}' match '#{cell}' ?"

          c = cell[0, 1]

          b = if c == '<' or c == '>'

            numeric_compare value, cell
          else

            range = to_ruby_range(cell)
            range ? range.include?(value) : regex_compare(value, cell)
          end

          return false unless b
        end

        #puts "__row matches"

        true
      end

      def regex_compare (value, cell)

        modifiers = 0
        modifiers += Regexp::IGNORECASE if @ignore_case

        rcell = Regexp.new(cell, modifiers)

        rcell.match(value)
      end

      def numeric_compare (value, cell)

        comparator = cell[0, 1]
        comparator += '=' if cell[1, 1] == '='
        cell = cell[comparator.length..-1]

        nvalue = Float(value) rescue value
        ncell = Float(cell) rescue cell

        if nvalue.is_a?(String) or ncell.is_a?(String)
          value = '"' + value + '"'
          cell = '"' + cell + '"'
        else
          value = nvalue
          cell = ncell
        end

        s = "#{value} #{comparator} #{cell}"

        #puts "...>>>#{s}<<<"

        #begin
        #  return Rufus::check_and_eval(s)
        #rescue Exception => e
        #end
        #false

        Rufus::check_and_eval(s) rescue false
      end

      def resolve_in_header (in_header)

        "${#{in_header}}"
      end

      def apply (row, hash)

        @header.outs.each_with_index do |out_header, icol|

          next unless out_header

          value = row[icol]

          next unless value
          #next unless value.strip.length > 0
          next unless value.length > 0

          value = Rufus::dsub value, hash

          hash[out_header] = if @accumulate
            #
            # accumulate

            v = hash[out_header]
            if v and v.is_a?(Array)
              v + Array(value)
            elsif v
              [ v, value ]
            else
              value
            end
          else
            #
            # override

            value
          end
        end
      end

      def parse_header_row (row)

        row.each_with_index do |cell, icol|

          next unless cell

          cell = cell.strip
          s = cell.downcase

          if s == 'ignorecase' or s == 'ignore_case'
            @ignore_case = true
            next
          end

          if s == 'through'
            @first_match = false
            next
          end

          if s == 'accumulate'
            @first_match = false
            @accumulate = true
            next
          end

          if Rufus::starts_with?(cell, 'in:') or \
             Rufus::starts_with?(cell, 'out:')

            @header = Header.new unless @header
            @header.add cell, icol
          end
        end
      end

      def empty_row? (row)

        return true unless row
        return true if (row.length == 1 and not row[0])
        row.each do |cell|
          return false if cell
        end
        true
      end

      # A regexp for checking if a string is a numeric Ruby range
      #
      RUBY_NUMERIC_RANGE_REGEXP = Regexp.compile(
        "^\\d+(\\.\\d+)?\\.{2,3}\\d+(\\.\\d+)?$")

      # A regexp for checking if a string is an alpha Ruby range
      #
      RUBY_ALPHA_RANGE_REGEXP = Regexp.compile(
        "^([A-Za-z])(\\.{2,3})([A-Za-z])$")

      # If the string contains a Ruby range definition
      # (ie something like "93.0..94.5" or "56..72"), it will return
      # the Range instance.
      # Will return nil else.
      #
      # The Ruby range returned (if any) will accept String or Numeric,
      # ie (4..6).include?("5") will yield true.
      #
      def to_ruby_range (s)

        range = if RUBY_NUMERIC_RANGE_REGEXP.match(s)

          eval(s)

        else

          m = RUBY_ALPHA_RANGE_REGEXP.match(s)

          m ? eval("'#{m[1]}'#{m[2]}'#{m[3]}'") : nil
        end

        class << range

          alias :old_include? :include?

          def include? (elt)

            elt = first.is_a?(Numeric) ? Float(elt) : elt

            old_include?(elt)
          end

        end if range

        range
      end

      class Header

        attr_accessor :ins, :outs

        def initialize

          @ins = []
          @outs = []
        end

        def add (cell, icol)

          if Rufus::starts_with?(cell, "in:")
            @ins[icol] = cell[3..-1]
            #puts "i added #{@ins[icol]}"
          elsif Rufus::starts_with?(cell, "out:")
            @outs[icol] = cell[4..-1]
            #puts "o added #{@outs[icol]}"
          end
          # else don't add
        end

        def to_csv

          s = ''
          @ins.each do |_in|
            s << "in:#{_in}," if _in
          end
          @outs.each do |out|
            s << "out:#{out}," if out
          end
          s[0..-2]
        end
      end
  end

end

