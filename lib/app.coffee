rp = require 'request-promise'
console = require 'console'
_ = require 'lodash'
moment = require 'moment'
Promise = require 'bluebird'
TuneGenie = require './tunegenie'
Spotify = require './spotify'
Bottleneck = require 'bottleneck'
fs = require 'fs'

config = require '../config'

saveConfig = =>
  strJson = JSON.stringify config, null, 2
  fs.writeFile '../config.json', strJson, (err) ->
    if err
      console.log "JSON failed to save: #{err}"
    else
      console.log "JSON saved!"

spotify = new Spotify(config.spotifyApi)

# Never more than 25 requests running at a time.
# Wait at least 150ms between batches
limiter = new Bottleneck 25, 150

spotify.ensureAuthenticated()
.then ->
  saveConfig()
  spotify.getUser()
.then ->
  _.each config.playlists, (playlist) ->
    tunegenie = new TuneGenie(playlist.brand)

    songs = switch playlist.type
      when 'topHits' then tunegenie.getTopHits()
      when 'onAir' then tunegenie.getOnAir(playlist.day, playlist.hours)
      else throw "Invalid playlist type: '#{playlist.type}'"

    songs.then (songs) ->
      console.log "Identified #{songs.length} potential tracks for #{playlist.name}"

      songs = _.map songs, (song) ->
        switch typeof config.songs[song]
          when "string" then config.songs[song]
          when "boolean" then false
          else song

      songs = _.reject songs, (song) -> song == false || song == ""

      tracks =_.map songs, (song) ->
        limiter.schedule spotify.searchForTrack, song

      Promise.all tracks
    .then (tracks) ->
      tracks = _.chain(tracks).filter().pluck('uri').value()
      spotify.createOrGetPlaylistId playlist
      .then (playlistId) ->
        playlist.playlistId = playlistId
        saveConfig()

        spotify.setTracks playlistId, tracks



