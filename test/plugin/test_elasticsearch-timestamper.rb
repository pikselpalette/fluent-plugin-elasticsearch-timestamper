require 'helper'
require 'time'

class ElasticsearchTimestampCheckerTest < Test::Unit::TestCase
  ENV["TZ"] = "Etc/UTC"
  setup do
    @tag = 'test1'
    @time = Time.local(1,2,3,4,5,2010,nil,nil,nil,nil)
  end

  CONFIG_TAG = %[
    tag test.${tag}
  ]

  def create_driver(conf=CONFIG_TAG, use_v1=true)
    Fluent::Test::OutputTestDriver.new(Fluent::ElasticsearchTimestampChecker, @tag).configure(conf, use_v1)
  end

  def emit(config=CONFIG_TAG, use_v1=true, msgs = [''])
    d = create_driver(config, use_v1)
    d.run do
      msgs.each do |record|
        d.emit(record, @time)
      end
    end

    @instance = d.instance
    d.emits
  end

  def test_format_timestrings
    recs = [
      {"timestamp" => '2016-11-13T12:33:01.000Z', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01.000000Z', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01.000000+0000', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01.000000+00:00', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01+00:00', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01+0000', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01', "a" => "b"},
      {"timestamp" => '2016-11-13T12:33:01.000', "a" => "b"},
      {"@timestamp" => '2016-11-13T12:33:01.000', "a" => "b"},
      {"time" => '2016-11-13T12:33:01.000', "a" => "b"},
    ]
    expected = {
      "a"           => "b",
      "@timestamp" => "2016-11-13T12:33:01.000000+0000",
    }

    emits = emit(CONFIG_TAG, true, recs)
    assert_equal 10, emits.size
    emits.each do |tag, time, record|
      assert_equal(expected, record)
    end
  end

  def test_format_timestamp
    rec = {"timestamp" => "1418973586", "a" => "b"}
    expected = {
      "a"           => "b",
      "@timestamp" => "2014-12-19T07:19:46.000000+0000",
    }

    emits = emit(CONFIG_TAG, true, [rec])
    assert_equal 1, emits.size
    emits.each do |tag, time, record|
      assert_equal(expected, record)
    end
  end

  def test_format_timestamp_ms
    rec = {"timestamp" => "1418973586001", "a" => "b"}
    expected = {
      "a"           => "b",
      "@timestamp" => "2014-12-19T07:19:46.001000+0000",
    }

    emits = emit(CONFIG_TAG, true, [rec])
    assert_equal 1, emits.size
    emits.each do |tag, time, record|
      assert_equal(expected, record)
    end
  end

  def test_format_no_timestamp
    rec = {"a" => "b"}
    expected = {
      "a"           => "b",
      "@timestamp" => "2010-05-04T03:02:01.000000+0000",
    }

    emits = emit(CONFIG_TAG, true, [rec])
    assert_equal 1, emits.size
    emits.each do |tag, time, record|
      assert_equal(expected, record)
    end
  end
end
