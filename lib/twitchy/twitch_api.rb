require 'open-uri'
require 'twitchy/dstruct'
require 'json'

module TwitchAPI
    @@PREFIX = "https://api.twitch.tv/kraken/"

    def self.get_follow_data(user)
        catch_exception(OpenURI::HTTPError) do
            get_as_struct("users/#{user}/follows/channels").follows
        end
    end

    def self.get_stream_status(streamers)
        query = "streams?channel=#{streamers.join(",")}"
        catch_exception(OpenURI::HTTPError, default: {}) do
            get_as_struct(query).streams.map do |s|
                [s.channel.name, s]
            end.to_h
        end
    end

    def self.get_stream_data(streamer)
        catch_exception(OpenURI::HTTPError) do
            get_as_struct("streams/#{streamer}").stream
        end
    end

    def self.get_videos(streamer, limit: 10, offset: 0, highlights: false)
        catch_exception(OpenURI::HTTPError) do
            query = "channels/#{streamer}/videos"\
                    "?broadcasts=#{!highlights}"\
                    "&limit=#{limit}&offset=#{offset}"
            get_as_struct(query).videos.each do |v|
                v.recorded_at = DateTime.parse(v.recorded_at)
            end
        end
    end

    def self.get_streamers_for_game(game, limit: 10, offset: 0)
        catch_exception(OpenURI::HTTPError) do
            query = "streams?game=#{URI.encode(game)}&limit=#{limit}&offset=#{offset}"
            get_as_struct(query).streams.map{|s| s.channel.name}
        end
    end

    private
    def self.catch_exception(exception, default: nil, &block)
        if block
            begin
                yield
            rescue exception
                default
            end
        else
            default
        end
    end

    def self.get(request)
        open( @@PREFIX + request ).each_line.to_a.join
    end

    def self.get_as_json(request)
        JSON.parse(get(request))
    end

    def self.get_as_struct(request)
        DeepStruct.new(get_as_json(request))
    end

end
