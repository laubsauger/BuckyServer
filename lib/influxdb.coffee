request = require('request')
dgram = require('dgram')

class Client
  constructor: (@config = {}, @logger) ->
    do @init

  init: ->
    useUDP = @config.get('influxdb.use_udp').get() ? false

    @send = if useUDP then @sendUDP() else @sendHTTP()

  write: (metrics) ->
    @send @metricsJson metrics

  sendHTTP: ->
    version = @config.get('influxdb.version').get() ? '0.9'
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 8086
    database = @config.get('influxdb.database').get() ? ''
    username = @config.get('influxdb.username').get() ? ''
    password = @config.get('influxdb.password').get() ? ''
    logger = @logger

    endpoint = 'http://' + host + ':' + port + '/write'

    client = request.defaults
      method: 'POST'
      url: endpoint
      qs:
        db: database
        u: username
        p: password

    (metricsJson) ->
      client form: metricsJson, (error, response, body) ->
        logger.log error if error
  sendUDP: ->
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 4444
    client = dgram.createSocket 'udp4'

    (metricsJson) ->
      message = new Buffer metricsJson

      client.send message, 0, message.length, port, host

  metricsJson: (metrics) ->
    version = @config.get('influxdb.version').get() ? '0.9'
    data =
      database: @config.get('influxdb.database').get() ? 'bucky'
      retentionPolicy: @config.get('influxdb.retentionPolicy').get() ? "default"
      time: new Date().toISOString()
      points: []
    for key, desc of metrics
      [val, unit, tags] = @parseRow desc

      data.points.push
        measurement: key
        fields:
          value: parseFloat val
          unit: unit
          tags: tags

    @logger.log(JSON.stringify(data, null, 2))
    JSON.stringify data

  parseRow: (row) ->
    re = /([0-9\.]+)\|([a-z]+)(?:@[0-9\.]+)?\|(.*)/

    groups = re.exec(row)

    unless groups
      @logger.log "Unparsable row: #{ row }"
      return

    groups.slice(1, 5)

module.exports = Client
