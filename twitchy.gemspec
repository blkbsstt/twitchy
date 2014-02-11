Gem::Specification.new do |s|
  s.name        = 'twitchy'
  s.version     = '0.1.1'
  s.date        = '2014-02-11'
  s.summary     = "A Ruby wrapper around livestreamer"
  s.description = "Twitchy provides for a system to query the TwitchAPI "\
                  "for use with livestreamer. List online channels, "\
                  "archived videos, and more."
  s.authors     = ["blkbsstt"]
  s.email       = 'blkbsstt+twitchy@gmail.com'
  s.executables << 'twitchy'
  s.files       = [
      "README.md",
      "twitchy.gemspec",
      "lib/twitchy/twitchy.rb",
      "lib/twitchy/livestreamer.rb",
      "lib/twitchy/dstruct.rb",
      "lib/twitchy/twitch_api.rb",
      "bin/twitchy"
  ]
  s.add_runtime_dependency "colorize", "~> 0.6"
  s.homepage    = 'http://www.github.com/blkbsstt/twitchy'
  s.license     = 'MIT'
end
