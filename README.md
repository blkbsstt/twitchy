# twitchy

A little Ruby wrapper around livestreamer

## Documentation

```
Usage: twitchy [options] [channel ..]
    -p, --player PLAYER              Set video player
    -c, --chat                       Open popout chat with the stream
    -u, --user USER                  Show subs for a user
    -q, --quality QUALITY            Set desired quality
    -v, --videos                     List archives instead of streams
    -l, --limit LIMIT                Number to fetch at once
    -g, --game GAME                  Add top streamers for GAME
        --highlights                 Only show highlights when fetching videos
    -h, --help                       Show this message
```
## Dependencies

Requires [`livestreamer`](https://github.com/chrippa/livestreamer) (obviously), and currently the [`colorize`](https://github.com/fazibear/colorize) and [`launchy`](http://www.copiousfreetime.org/projects/launchy) gems.

## Installation

`gem install twitchy`

## Todo

~~I plan on gemifying this soon.~~ Also, a lot of usage is unclear (pagination in 
archives, quality options, https://github.com/fazibear/colorizeetc).

I have greatly reduced API requests from earlier versions, but I'm always keeping an eye out for ways to bring the number of those calls down further. There's a way to get all the videos from subscriptions of a user, but it requires authentication and isn't very flexible, for example, so right now I'm making calls for each requested channel.
