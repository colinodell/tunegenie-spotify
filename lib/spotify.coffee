SpotifyWebApi = require 'spotify-web-api-node'
Promise = require 'bluebird'
console = require 'console'
_ = require 'lodash'

class Spotify
  constructor: (@credentials) ->
    @api = new SpotifyWebApi(@credentials)

  ensureAuthenticated: ->
    console.log 'Checking oauth tokens...'
    if not @credentials.refreshToken
      # Create the authorization URL
      scopes = ['playlist-modify-public', 'playlist-modify-private']
      authorizeURL = @api.createAuthorizeURL scopes, 'state'
      throw "Authentication required: visit #{authorizeURL}"
      # TODO: Implement functionality for authorizationCodeGrant and saving tokens

    @api.refreshAccessToken()
    .then (data) =>
      console.log 'Refreshed oauth token successfully'
      @api.setAccessToken data.body.access_token

  getUser: =>
    @api.getMe()
    .then (data) =>
      @credentials.user = data.body.id

  createOrGetPlaylistId: (playlistConfig) =>
    if playlistConfig.playlistId?
      id = playlistConfig.playlistId
      console.log "Using existing playlist #{id}: #{playlistConfig.name}"
      Promise.resolve id
    else
      @api.createPlaylist @credentials.user, playlistConfig.name, playlistConfig.public
      .then (data) ->
        id = data.body.id
        console.log "Created playlist #{id}: #{playlistConfig.name}"
        playlistConfig.playlistId = id

  setTracks: (playlistId, tracks) ->
    console.log "Adding #{tracks.length} tracks to playlist #{playlistId}"

    # Spotify won't let you more than 100 tracks at a time
    # I even had errors with 100, so I dropped this to 80 which works fine
    tracks = _.chunk tracks, 80

    # The first call should replace all tracks with the first chunk
    current = @api.replaceTracksInPlaylist @credentials.user, playlistId, tracks.shift()

    # Use the normal add calls for any remaining chunks
    Promise.map tracks, (trackSet) =>
      current = current.then () =>
        @api.addTracksToPlaylist @credentials.user, playlistId, trackSet


  searchForTrack: (query) =>
    @api.searchTracks query, limit: 1
    .then (data) ->
      if data.body.tracks.items.length == 0
        console.log "Failed to locate '#{query}' in Spotify"
        return null

      track = data.body.tracks.items[0]

      return {
        artist: track.artists[0].name
        album: track.album.name
        track: track.name
        id: track.id
        uri: track.uri
      }

module.exports = Spotify
