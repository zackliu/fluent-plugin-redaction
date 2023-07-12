require 'json'

module Fluent
    module Plugin
        class RedactionFilter < Fluent::Plugin::Filter
            Fluent::Plugin.register_filter("redaction", self)

            helpers :record_accessor

            config_section :rule, param_name: :rule_config_list, required: true, multi: true do
                config_param :key, :string, default: nil
                config_param :value, :string, default: nil
                config_param :pattern, :regexp, default: nil
                config_param :replace, :string, default: "[REDACTED]"
            end

            def initialize
                @pattern_rules_map = {}
                @accessors = {}
                super
            end
          
            def configure(conf)
                super

                @rule_config_list.each do |c|
                    unless c.key
                        key_missing = true
                    end
                    if key_missing
                        raise Fluent::ConfigError, "Field 'key' is missing from rule section. #{c}"
                    end
                    unless c.value || c.pattern
                        value_missing = true
                    end
                    if value_missing
                        raise Fluent::ConfigError, "Field 'value' or 'pattern' is missing from rule section for key: #{c.key}."
                    end
                    record_accessor = record_accessor_create(c.key)
                    @accessors["#{c.key}"] = record_accessor
                    list = []
                    if @pattern_rules_map.key?(c.key)
                        list = @pattern_rules_map[c.key]
                    end
                    list << [c.value, c.pattern, c.replace]
                    @pattern_rules_map[c.key] = list
                end
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