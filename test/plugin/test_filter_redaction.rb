require 'bundler/setup'
require 'test/unit'
require 'fluent/log'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_redaction'

class RubyFilterTest < Test::Unit::TestCase
  include Fluent

  CONFIG = %[
    key message
    value hell
    <rule>
      key message
      value hell
    </rule>
  ]

  PATTERN_CONFIG = %[
    key message
    pattern /(hell)/
    <rule>
      key message
      pattern /(hell)/
    </rule>
  ]

  setup do
    Fluent::Test.setup
  end

  def emit(msg, conf='')
    d = Test::Driver::Filter.new(Plugin::RedactionFilter).configure(conf)
    d.run(default_tag: 'test') {
      d.feed(msg)
    }
    d.filtered
  end

  sub_test_case 'filter' do
    test 'Filter hell from hello messages with simple value' do
      msg = {'message' => 'hello hello'}
      es  = emit(msg, CONFIG)
      assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["message"]}")
    end
  end

  sub_test_case 'filter' do
    test 'Filter hell from hello messages with pattern' do
      msg = {'message' => 'hello hello'}
      es  = emit(msg, PATTERN_CONFIG)
      assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["message"]}")
    end
  end

end