require 'json'

module Fluent
    module Plugin
        class RedactionFilter < Fluent::Plugin::Filter
            Fluent::Plugin.register_filter("redaction", self)

            config_section :rule, param_name: :rule_list, required: true, multi: true do
                config_param :key, :string, default: nil,
                config_param :value, :string, default: nil
                config_param :value_pattern, :string, default: nil
                config_param :replacement, :string, default: "[REDACTED]"
            end

            def initialize
                super
            end
          
            def configure(conf)
                super
            end

            def filter(tag, es)
            end
        end
    end
end