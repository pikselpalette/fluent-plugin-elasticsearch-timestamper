# fluent-plugin-elasticsearch-timestamper [![Build Status](https://travis-ci.org/pikselpalette/fluent-plugin-elasticsearch-timestamper.png)](https://travis-ci.org/pikselpalette/fluent-plugin-elasticsearch-timestamper)
Fluent plugin to ensure @timestamp is in correct format for elasticsearch

## Install

```bash
gem install fluent-plugin-elasticsearch-timestamper
```

## Description

The purpose of this filter is to make sure the @timestamp field exists in the
record which is necessary for the record to be indexed properly by
elasticsearch.

## Usage

```
<filter **>
  type elasticsearch_timestamper
</filter>
```
