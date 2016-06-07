require_relative '../helper'
require 'fluent/test'
require 'fluent/output'
require 'fluent/plugin/out_elasticsearch_timestamper'

CONFIG = %[
  tag test.tag
]

CONFIG_NONE = %[]

CONFIG_TAG_SHIFT = %[
  tag_shift true
]

CONFIG_TIME_KEY = %[
  tag foo
  time_key timestamp
]

CONFIG_TIME_MS = %[
  tag foo
  time_format epoch_ms
]

CONFIG_TIME_SEC = %[
  tag foo
  time_format epoch
]

CONFIG_TIME_BAD_FMT = %[
  tag foo
  time_format epoch_nothing
]

describe Fluent::ElasticsearchTimestampCheckFilter do
  before { Fluent::Test.setup }
  let(:tag) { 'test.tag' }
  let(:driver) { Fluent::Test::OutputTestDriver.new(Fluent::ElasticsearchTimestampCheckFilter, tag).configure(config) }

  describe 'test configure' do
    describe 'good configuration' do
      subject { driver.instance }

      context "check default" do
        let(:config) { CONFIG }
        it { expect { subject }.not_to raise_error }
      end

      context "check tag_shift" do
        let(:config) { CONFIG_TAG_SHIFT }
        it { expect { subject }.not_to raise_error }
      end

      context "check time_key" do
        let(:config) { CONFIG_TIME_KEY }
        it { expect { subject }.not_to raise_error }
      end

      context "check time_format epoch" do
        let(:config) { CONFIG_TIME_SEC }
        it { expect { subject }.not_to raise_error }
      end

      context "check time_format epoch_ms" do
        let(:config) { CONFIG_TIME_MS }
        it { expect { subject }.not_to raise_error }
      end
    end

    describe 'bad configuration' do
      subject { driver.instance }

      context "tag is not specified" do
        let(:config) { CONFIG_NONE }
        it { expect { subject }.to raise_error(Fluent::ConfigError) }
      end

      context "bad time format" do
        let(:config) { CONFIG_TIME_BAD_FMT }
        it { expect { subject }.to raise_error(Fluent::ConfigError) }
      end

    end
  end
  describe 'test emit' do
    let(:time) { Time.now }
    let(:emit) {
      driver.run { driver.emit({'foo'=>'bar', 'message' => '1'}, time.to_i) }
    }

    context 'typical usage' do
      let(:config) { CONFIG }
      let(:emit) {
        driver.run do
          driver.emit({'foo'=>'bar', 'message' => '1'}, time.to_i)
          driver.emit({'foo'=>'bar', 'message' => '2'}, time.to_i)
        end
      }
      before do
        Fluent::Engine.stub(:now).and_return(time)

        Fluent::Engine.should_receive(:emit).with("#{tag}", time.to_i, {
          'foo'        => 'bar',
          'message'    => "1",
          '@timestamp' => DateTime.strptime(time.to_i.to_s, '%s').strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
        Fluent::Engine.should_receive(:emit).with("#{tag}", time.to_i, {
          'foo'        => 'bar',
          'message'    => "2",
          '@timestamp' => DateTime.strptime(time.to_i.to_s, '%s').strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
      end
      it { expect { emit }.not_to raise_error }
    end

    context 'with tag_shift' do
      let(:config) { CONFIG_TAG_SHIFT }
      before do
        Fluent::Engine.stub(:now).and_return(time)

        Fluent::Engine.should_receive(:emit).with("tag", time.to_i, {
          'foo'        => 'bar',
          'message'    => "1",
          '@timestamp' => DateTime.strptime(time.to_i.to_s, '%s').strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
      end
      it { expect { emit }.not_to raise_error }
    end

    context 'with time_key' do
      let(:config) { CONFIG_TIME_KEY }
      let(:emit) {
        driver.run { driver.emit({'foo'=>'bar', 'message' => '1', 'timestamp' => time.to_s}, time.to_i) }
      }
      before do
        Fluent::Engine.stub(:now).and_return(time)

        Fluent::Engine.should_receive(:emit).with("foo", time.to_i, {
          'foo'        => 'bar',
          'message'    => "1",
          'timestamp'  => time.to_s,
          '@timestamp' => DateTime.parse(time.to_s).strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
      end
      it { expect { emit }.not_to raise_error }
    end

    context 'with time_format epoch' do
      let(:config) { CONFIG_TIME_SEC }
      let(:emit) {
        driver.run { driver.emit({'foo'=>'bar', 'message' => '1', 'time' => time.to_i}, time.to_i) }
      }
      before do
        Fluent::Engine.stub(:now).and_return(time)

        Fluent::Engine.should_receive(:emit).with("foo", time.to_i, {
          'foo'        => 'bar',
          'message'    => "1",
          'time'       => time.to_i,
          '@timestamp' => DateTime.parse(time.to_s).strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
      end
      it { expect { emit }.not_to raise_error }
    end

    context 'with time_format epoch_ms' do
      let(:config) { CONFIG_TIME_MS }
      let(:emit) {
        driver.run { driver.emit({'foo'=>'bar', 'message' => '1', 'time' => DateTime.parse(time.to_s).strftime('%Q').to_i}, time.to_i) }
      }
      before do
        Fluent::Engine.stub(:now).and_return(time)

        Fluent::Engine.should_receive(:emit).with("foo", time.to_i, {
          'foo'        => 'bar',
          'message'    => "1",
          'time'       => DateTime.parse(time.to_s).strftime('%Q').to_i,
          '@timestamp' => DateTime.parse(time.to_s).strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
        })
      end
      it { expect { emit }.not_to raise_error }
    end
  end
end
