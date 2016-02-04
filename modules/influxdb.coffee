_ = require('underscore')

InfluxDB = require '../lib/influxdb'

module.exports = ({config, app, logger}, next) ->
  influxdb = new InfluxDB config, logger

  next
    send: (data, {req}) ->
      isInternalRequest = true if req.ip.indexOf config.get('server.internalIpFragment').get() > -1

      if isInternalRequest
        influxdb.write data
