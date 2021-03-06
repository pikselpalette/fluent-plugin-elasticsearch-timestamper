require 'fluent/mixin/rewrite_tag_name'

module Fluent
  class ElasticsearchTimestampChecker < Output
    Fluent::Plugin.register_output('elasticsearch_timestamper', self)
    include Fluent::HandleTagNameMixin
    include Fluent::Mixin::RewriteTagName
    require 'date'

    attr_accessor :tag, :hostname_command

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super
      @tag = conf['tag'] if conf['tag']
      @hostname_command = conf['hostname_command'] if conf['hostname_command']
      if ( !@tag && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix )
        raise Fluent::ConfigError, "elasticsearch_timestamper: missing remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format_time(ts)
      ts = ts.to_s
      if ts =~ /^\d+$/
        if ts.length == 10
          DateTime.strptime(ts, '%s')
        elsif ts.length == 13
          DateTime.strptime(ts, '%Q')
        else
          raise "Wrong time_format: #{ts}"
        end
      else
        DateTime.parse(ts)
      end
    end

    def format_record(time, record)
      existing = record.delete("@timestamp") || record.delete("timestamp") || record.delete("time") || time
      record["@timestamp"] = format_time(existing).strftime('%Y-%m-%dT%H:%M:%S.%6L%z')
      record
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        emit_tag = tag.dup
        filter_record(emit_tag, time, record)
        new_record = format_record(time, record)
        Engine.emit(emit_tag, time, new_record)
      end
      chain.next
    end
  end
end
