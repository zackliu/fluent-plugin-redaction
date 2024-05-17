require 'json'

module Fluent
    module Plugin
        class RedactionAltFilter < Fluent::Plugin::Filter
            Fluent::Plugin.register_filter("redaction_alt", self)

            helpers :record_accessor

            config_param :rule_file, :string, default: nil
            config_param :refresh_interval_seconds :integer, default: 60

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
                  raise Fluent::ConfigError, "Field 'rule_file' is missing or the file is not exist: #{@rule_file}"
                end

                timer_execute(:redaction_file_watch, @refresh_interval_seconds, repeat: true) do
                  load_rules_from_file if @rule_file
                end
            end

            def load_rules_from_file
              begin
                rule_conf = Fluent::Config.build(@rule_file)
                setup_rules(rule_conf)
              rescue => e
                  log.warn "Failed to load rules from file: #{@rule_file} - #{e}"
              end
            end

            def setup_rules(rule_conf)
              rules.each do |r|
                log.info "Adding rule: #{r}"
              end
            end

            def validate_rule(rule)
              raise Fluent::ConfigError, "Field 'key' is missing for rule." unless rule['key']
              raise Fluent::ConfigError, "Field 'value' or 'pattern' is missing for key: #{rule['key']}." unless rule['value'] || rule['pattern']
            end

            def filter(tag, time, record)
                @pattern_rules_map.each do |key, rules|
                    record_value = @accessors[key].call(record)
                    if record_value
                        rules.each do | rule |
                            if rule[0]
                                record_value = record_value.gsub(rule[0], rule[2])
                            else
                                record_value = record_value.gsub(rule[1], rule[2])
                            end
                        end
                        @accessors[key].set(record, record_value)
                    end
                end
                record
            end
        end
    end
end
