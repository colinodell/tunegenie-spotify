# tunegenie-spotify

A small side-project to automatically create/update Spotify playlists with songs played by [my favorite radio station](http://www.wbru.com) (as recorded by TuneGenie).

It currently supports two modes of operation:

- Top Hits (whatever TuneGenie lists as the most-popular songs)
- On Air (all tracks played in the last `x` hours)

This was created for my personal/educational use only. There are several issues and incomplete features which may never be fully implemented. Hopefully someone else may find the code useful though.

Please also see the [`LICENSE`](LICENSE).

## Installation & Configuration

You'll need to `npm install` as usual.

Copy `config.example.json` to `config.json` and update the `CHANGEME` fields accordingly.

OAuth2 is only partially implemented - you'll need to manually generate the grant code and obtain the initial access & refresh tokens yourself:

1. Register a new application in Spotify.  Set the `clientId` and `clientSecret` values in `config.json` accordingly.
2. Create a fake `redirectUri`. Pop that into both `config.json` and the Spotify app configuration.
3. Run this app.  You'll get an error like `Authentication required: visit http://someurl.com`.  Go there.
4. Once you complete step 3, you'll get redirected to that fake URL. It will contain a code.  You'll need to copy that and manually run [code like this](https://github.com/thelinmichael/spotify-web-api-node#authorization-code-flow) to obtain the tokens using that code.
5. Save the resulting `accessToken` and `refreshToken` to `config.json`.

This tool should automatically handle refreshing the token as needed (barely tested).  The manual process above is currently required because A) I'm lazy, and B) it requires a public-facing web-app, which this tool isn't.  Perhaps one day I'll figure out a better solution...

### Playlists

You can configure any number of playlists. Each one requires the following fields:

- `name` - The name of the playlist (as you'd like it to appear in Spotify
- `public` - Whether the playlist should be publically-visible
- `brand` - The subdomain of tunegenie.com. So if you want data from `wbru.tunegenie.com`, set this to `wbru`
- `type` - Either `topHits` or `onAir`

If the `type` is `onAir`, you'll also want to provide:

- `hours` - Determines how far back in time (in hours) to look.  More hours = more songs.

Upon creating the playlist, this tool will also add an additional configuration item:

- `playlistId` - The Spotify ID of the playlist; used to update the existing playlist on subsequent runs

## Usage

Honestly, I've just been running `app.coffee` from my IDE.  There's a script in `bin` which may (or may not) work - I haven't actually tested it.

Good luck and happy coding!
