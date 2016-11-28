module Fluent
  class ElasticsearchTimestampChecker < Output
    Fluent::Plugin.register_output('elasticsearch_timestamper', self)
    require 'date'
    config_param :tag, :string, :desc => 'The output tag name.'

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super
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
        new_record = format_record(time, record)
        router.emit(@tag, time, new_record)
      end
      chain.next
    end
  end
end
