require 'json'

module Fluent
    module Plugin
        class RedactionAltFilter < Fluent::Plugin::Filter
            Fluent::Plugin.register_filter("redaction_alt", self)
            DEFAULT_VALUE = "[REDACTED]"

            helpers :record_accessor
            helpers :timer

            config_param :rule_file, :string, default: nil
            config_param :refresh_interval_seconds, :integer, default: 60

            def initialize
                @pattern_rules_map = {}
                @accessors = {}
                super
            end

            def configure(conf)
                super

                if @rule_file && File.exist?(@rule_file)
                  load_rules_from_file
                else
                  raise Fluent::ConfigError, "Field 'rule_file' is missing or the file is not exist: #{@rule_file} in current directory: #{Dir.getwd}"
                end

                timer_execute(:redaction_file_watch, @refresh_interval_seconds, repeat: true) do
                  load_rules_from_file if @rule_file
                end
            end

            def load_rules_from_file
              begin
                rule_conf = Fluent::Config.build(config_path: @rule_file)
                setup_rules(rule_conf)
              rescue => e
                puts "Failed to load rules from file: #{@rule_file} - #{e}"
                  log.warn "Failed to load rules from file: #{@rule_file} - #{e}"
              end
            end

            def setup_rules(rule_conf)
              pattern_rules_map = {}
              rule_conf.elements.each do |r|
                raise Fluent::ConfigError, "Field 'key' is missing for rule." unless r['key']
                raise Fluent::ConfigError, "Field 'pattern' is missing for key: #{r['key']}." unless r['pattern']

                record_accessor = record_accessor_create(r['key'])
                @accessors["#{r['key']}"] = record_accessor
                list = []
                if pattern_rules_map.key?(r.key)
                    list = pattern_rules_map[r.key]
                end
                replace = r["replace"].to_s.empty? ? DEFAULT_VALUE : r["replace"]
                list << [r.pattern, replace]
                pattern_rules_map[r.key] = list
              end
              @pattern_rules_map = pattern_rules_map
              puts @pattern_rules_map
            end

            def filter(tag, time, record)
                @pattern_rules_map.each do |key, rules|
                    record_value = @accessors[key].call(record)
                    if record_value
                        rules.each do | rule |
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
