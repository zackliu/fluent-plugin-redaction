require "bundler/setup"
require "test/unit"
require "fluent/log"
require "fluent/test"
require "fluent/test/driver/filter"
require "fluent/plugin/filter_redaction_alt"

class RubyFilterTest < Test::Unit::TestCase
  include Fluent

  def getConfig(rule_file)
    %[
      rule_file #{rule_file}
      refresh_interval_seconds 0.1
    ]
  end

  setup do
    Fluent::Test.setup
  end

  def emit(msg, conf = "")
    d = Test::Driver::Filter.new(Plugin::RedactionAltFilter).configure(conf)
    d.run(default_tag: "test") {
      d.feed(msg)
    }
    d.filtered
  end

  def assert_until_timeout(timeout, interval)
    begin
      last_error = ""
      Timeout.timeout(timeout) do
        loop do
          begin
            yield
            break # Exit loop if assertions pass
          rescue => e
            last_error = e
            sleep interval
          end
        end
      end
    rescue Timeout::Error
      raise "Test failed: conditions not met within #{timeout} seconds with last error #{last_error}"
    end
  end

  sub_test_case "filter" do
    test "Filter hell from hello messages with simple pattern" do
      msg = { "message" => "hello hello" }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["message"]}")
    end

    test "Filter hell from hello messages with simple pattern and replace with specified value" do
      msg = { "replaceMessage" => "hello hello" }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("*****o *****o", "#{es[0][1]["replaceMessage"]}")
    end

    test "Filter hell from multiple keys" do
      msg = { "multikey1" => "hello hello", "multikey2" => "hella", "multikey3" => "hello" }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["multikey1"]}")
      assert_equal("[REDACTED]a", "#{es[0][1]["multikey2"]}")
      assert_equal("hello", "#{es[0][1]["multikey3"]}")
    end

    test "Filter only available in rule tag" do
      msg = { "rule2" => "hello hello" }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("hello hello", "#{es[0][1]["rule2"]}")
    end

    test "Filter in complex rule 1" do
      msg = { "userId" => "code=abcde" }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("code=[REDACTED]", "#{es[0][1]["userId"]}")
    end

    test "Filter in complex rule 2" do
      msg = { "properties" => { "userId" => "access_token=abcde" } }
      es = emit(msg, getConfig("test/plugin/test_rule_file"))
      assert_equal("access_token=[REDACTED]", "#{es[0][1]["properties"]["userId"]}")
    end
  end

  sub_test_case "error" do
    test "File not exist should throw error" do
      msg = { "message" => "hello hello" }
      assert_raise(Fluent::ConfigError) do
        emit(msg, getConfig("test/plugin/test_rule_file_notexist"))
      end
    end

    test "Invalid format should throw error" do
      msg = { "message" => "hello hello" }
      assert_raise(Fluent::ConfigError) do
        emit(msg, getConfig("test/plugin/test_rule_file_invalid"))
      end
    end
  end

  sub_test_case "hot_reload" do
    test "Rule file update should trigger hot reload" do
      rule_file_path = "test/plugin/test_rule_file_ephemeral"
      begin
        config1 = <<~RULE
          <rule>
            key message
            pattern /hell/
          </rule>
        RULE

        config2 = <<~RULE
          <rule>
            key message2
            pattern /hell/
            replace *****
          </rule>
        RULE

        File.open(rule_file_path, "w") do |file|
          file.write(config1)
        end

        d = Test::Driver::Filter.new(Plugin::RedactionAltFilter).configure(getConfig(rule_file_path))
        d.run(default_tag: "test") do
          d.feed({ "message" => "hello hello", "message2" => "hello hello" })

          es = d.filtered
          assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["message"]}")
          assert_equal("hello hello", "#{es[0][1]["message2"]}")

          File.open(rule_file_path, "w") do |file|
            file.write(config2)
          end

          assert_until_timeout(2, 0.1) do
            d.feed({ "message" => "hello hello", "message2" => "hello hello" })
            es = d.filtered
            assert_equal("hello hello", "#{es[-1][1]["message"]}")
            assert_equal("*****o *****o", "#{es[-1][1]["message2"]}")
          end
        end
      ensure
        File.delete(rule_file_path) if File.exist?(rule_file_path)
      end
    end

    test "Rule file update should not update if file is invalid or empty" do
      rule_file_path = "test/plugin/test_rule_file_ephemeral2"
      begin
        config1 = <<~RULE
          <rule>
            key message
            pattern /hell/
          </rule>
        RULE

        config2 = <<~RULE
          <rule>
            keyss message2
            pattern /hell/
            replace *****
          </rule>
        RULE

        config3 = <<~RULE
          <rule>
            key message2
            pattern /hell/
            replace *****
          </rule>
        RULE

        File.open(rule_file_path, "w") do |file|
          file.write(config1)
        end

        d = Test::Driver::Filter.new(Plugin::RedactionAltFilter).configure(getConfig(rule_file_path))
        d.run(default_tag: "test") do
          d.feed({ "message" => "hello hello", "message2" => "hello hello" })

          es = d.filtered
          assert_equal("[REDACTED]o [REDACTED]o", "#{es[0][1]["message"]}")
          assert_equal("hello hello", "#{es[0][1]["message2"]}")

          File.delete(rule_file_path) if File.exist?(rule_file_path)

          sleep 0.3
          d.feed({ "message" => "hello hello", "message2" => "hello hello" })
          es = d.filtered
          assert_equal("[REDACTED]o [REDACTED]o", "#{es[-1][1]["message"]}")
          assert_equal("hello hello", "#{es[-1][1]["message2"]}")

          File.open(rule_file_path, "w") do |file|
            file.write(config2)
          end

          sleep 0.3
          d.feed({ "message" => "hello hello", "message2" => "hello hello" })
          es = d.filtered
          assert_equal("[REDACTED]o [REDACTED]o", "#{es[-1][1]["message"]}")
          assert_equal("hello hello", "#{es[-1][1]["message2"]}")

          File.open(rule_file_path, "w") do |file|
            file.write(config3)
          end

          assert_until_timeout(2, 0.1) do
            d.feed({ "message" => "hello hello", "message2" => "hello hello" })
            es = d.filtered
            assert_equal("hello hello", "#{es[-1][1]["message"]}")
            assert_equal("*****o *****o", "#{es[-1][1]["message2"]}")
          end
        end
      ensure
        File.delete(rule_file_path) if File.exist?(rule_file_path)
      end
    end
  end
end
