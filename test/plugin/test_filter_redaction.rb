require 'bundler/setup'
require 'test/unit'
require 'fluent/log'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_redaction'

class RubyFilterTest < Test::Unit::TestCase
  include Fluent

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

  #sub_test_case 'filter' do
  #  test 'execute to jsonl array' do
  #      assert_equal(msg[i], e[0])
  #    end
  #  end
  #end
end