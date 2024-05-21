require "json"

module Fluent
  module Plugin
    class RedactionAltFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("redaction_alt", self)
      DEFAULT_REDACTED_VALUE = "[REDACTED]"
      TAG_NAME = "rule"

      helpers :record_accessor
      helpers :timer

      config_param :rule_file, :string, default: nil
      config_param :refresh_interval_seconds, :float, default: 60

      def initialize
        @pattern_rules_map = {}
        @accessors = {}
        super
      end

      def start
        super
        timer_execute(:redaction_file_watch, @refresh_interval_seconds, repeat: true) do
          log.debug "timer execute: #{@refresh_interval_seconds}"
          load_rules_from_file(true)
        end
      end

      def configure(conf)
        super

        if @rule_file && File.exist?(@rule_file)
          load_rules_from_file(false)
        else
          raise Fluent::ConfigError, "Field 'rule_file' is missing or the file is not exist: #{@rule_file} in current directory: #{Dir.getwd}"
        end
      end

      def load_rules_from_file(reload)
        begin
          rule_conf = Fluent::Config.build(config_path: @rule_file)
          setup_rules(rule_conf)
        rescue => e
          log.warn "Failed to load rules from file: #{@rule_file} - #{e}"
          if !reload
            raise e
          end
        end
      end

      def setup_rules(rule_conf)
        pattern_rules_map = {}
        accessors = {}
        rule_conf.elements.each do |r|
          if r.name != TAG_NAME
            next
          end

          raise Fluent::ConfigError, "Field 'key' is missing for rule." unless r["key"]
          raise Fluent::ConfigError, "Field 'pattern' is missing for key: #{r["key"]}." unless r["pattern"]

          keys = r["key"].split
          keys.each do |key|
            record_accessor = record_accessor_create(key)
            accessors["#{key}"] = record_accessor
            list = []
            if pattern_rules_map.key?(key)
              list = pattern_rules_map[key]
            end
            replace = r["replace"].to_s.empty? ? DEFAULT_REDACTED_VALUE : r["replace"]
            pattern = Fluent::Config::regexp_value(r["pattern"])
            list << [pattern, replace]
            pattern_rules_map[key] = list
          end
        end
        @pattern_rules_map = pattern_rules_map
        @accessors = accessors
        log.debug "Pattern rules: #{@pattern_rules_map}"
        # puts "Pattern rules: #{@pattern_rules_map} in config #{@rule_file}"
      end

      def filter(tag, time, record)
        @pattern_rules_map.each do |key, rules|
          record_value = @accessors[key].call(record)
          if record_value
            rules.each do |rule|
              record_value = record_value.gsub(rule[0], rule[1])
            end
            @accessors[key].set(record, record_value)
          end
        end
        record
      end
    end
  end
end
