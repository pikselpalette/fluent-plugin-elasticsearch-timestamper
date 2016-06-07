module Fluent
  class ElasticsearchTimestampCheckFilter < Output
    Fluent::Plugin.register_output('elasticsearch_timestamper', self)

    config_param :tag,         :string, :default => nil
    config_param :tag_shift,   :bool,   :default => false
    config_param :time_key,    :string, :default => 'time'
    config_param :time_format, :string, :default => 'stamp'

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super

      unless ['stamp', 'epoch', 'epoch_ms'].include? @time_format
        raise Fluent::ConfigError, "out_elasticsearch_timestamper: wrong time format"
      end

      if @tag.nil? and not @tag_shift
        raise Fluent::ConfigError, "out_elasticsearch_timestamper: one of `tag_shift` or `tag` must be specified"
      end

      require 'date'
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format_time(ts, format = nil)
      fmt = '%Y-%m-%dT%H:%M:%S.%L%z'
      time_fmt = format || @time_format

      case time_fmt
      when 'stamp'
        DateTime.parse(ts).strftime(fmt)
      when 'epoch'
        DateTime.strptime(ts.to_s, '%s').strftime(fmt)
      when 'epoch_ms'
        DateTime.strptime(ts.to_s, '%Q').strftime(fmt)
      end
    end

    def emit(tag, es, chain)
      last_record = nil

      es.each do |time, record|
        last_record = record # for debug log
        new_tag = @tag_shift ? tag.split('.')[1..-1].join('.') : @tag
        existing = record[@time_key]
        if existing
          record['@timestamp'] = format_time(existing)
        else
          record['@timestamp'] = format_time(time, 'epoch')
        end
        Engine.emit(new_tag, time, record)
      end

      chain.next

    rescue => e
      log.warn "out_elasticsearch_timestamper: #{e.class} #{e.message} #{e.backtrace.first}"
      log.debug "out_elasticsearch_timestamper: tag:#{@tag} record:#{last_record}"
    end
  end
end
