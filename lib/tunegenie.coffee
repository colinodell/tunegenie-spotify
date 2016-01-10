rp = require 'request-promise'
console = require 'console'
_ = require 'lodash'
moment = require 'moment'
Promise = require 'bluebird'

class TuneGenie
  constructor: (@brand) ->

  getTopHits: () ->
    doRequest "http://#{@brand}.tunegenie.com/api/v1/brand/tophits/", "http://#{@brand}.tunegenie.com/tophits/"

  getOnAir: (day, hours, minimumPlays = 1) ->
    day = moment().day(day).subtract(1, 'week').endOf('day');
    periods = getHourlyPeriods day, hours

    requests = _.map periods, getHourlySongs, this

    Promise.all requests
    .then (songsByHour) ->
      _.chain(songsByHour)
      .flatten()
      .countBy()
      .pairs()
      .sortBy(1)
      .reverse()
      .pluck(0)
      .value()

  getHourlyPeriods = (startDate, hours) ->
    # Rewind to the top of the hour
    startDate.minute(0).second(0).millisecond(0)

    # Make a list of times by subtracting one hour and returning that date and time
    num = hours + 1
    while num -= 1
      startDate.subtract(1, 'hours').clone()

  getHourlySongs = (start) ->
    start = moment(start).minute(0).second(0).millisecond(0)
    end = start.clone().minute(59).second(59)

    url = "http://#{@brand}.tunegenie.com/api/v1/brand/nowplaying/?hour=#{start.hour()}&since=#{start.format()}&until=#{end.format()}"
    doRequest url, "http://#{@brand}.tunegenie.com/onair/"

  doRequest = (url, referer) ->
    options =
      uri: url
      headers:
        'Referer': referer

    rp options
    .then (data) ->
      data = JSON.parse data
      songs = data.response
      _.map songs, (item) -> "#{item.artist} - #{item.song}"

module.exports = TuneGenie
