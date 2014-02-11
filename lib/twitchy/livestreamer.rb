require 'json'

module Livestreamer
    @@sort = ["best","source","high","medium","low","mobile","worst"]

    def self.get_available_streams(channel)
        @@sort & JSON.parse(`livestreamer -j twitch.tv/#{channel}`)["streams"].keys
    end

    def self.start_stream(channel, player, quality, chat)
        stream = "livestreamer -Q -p '#{player}' "\
                 "twitch.tv/#{channel} #{quality} & "
        popout_chat = "firefox -new-window "\
               "'http://www.twitch.tv/chat/embed"\
               "?channel=#{channel}&popout_chat=true' "\
               "&> /dev/null & "
        cmd = stream
        cmd += popout_chat if chat

        exec cmd
    end

    def self.start_video(url, player)
        exec "livestreamer -Q -p '#{player}' "\
             "#{url} best &"
    end
end
