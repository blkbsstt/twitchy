require 'colorize'
require 'optparse'
require 'ostruct'
require 'twitchy/livestreamer'
require 'twitchy/twitch_api'

class Twitchy
    attr_reader :options, :streamers, :online

    def initialize(args)
        parse_options(args)

        @streamers = args.map{|s| s.dup}
        @streamers += fetch_subs(@options.user) if @options.user
        @streamers += TwitchAPI.get_streamers_for_game(
            @options.game, limit: @options.limit
        ) if @options.game
    end

    def parse_options(args)
        @options = OpenStruct.new(
            player:     "vlc --no-video-title-show",
            quality:    "best",
            chat:       false,
            videos:     false,
            limit:      20,
            highlights: false,
            game:       nil
        )
        @optparser = OptionParser.new do |opts|
            opts.banner = "Usage: twitchy [options] [channel ..]"

            opts.on("-p", "--player PLAYER", "Set video player") do |p|
                @options.player = p
            end

            opts.on("-c", "--chat", "Open popout chat with the stream") do
                @options.chat = true
            end

            opts.on("-u", "--user USER", "Show subs for a user") do |u|
                @options.user = u
            end

            opts.on("-q", "--quality QUALITY", "Set desired quality") do |q|
                @options.quality = q
            end

            opts.on("-v", "--videos", "List archives instead of streams") do
                @options.videos = true
            end

            opts.on("-l", "--limit LIMIT", Integer, "Number to fetch at once") do |l|
                @options.limit = l
            end

            opts.on("-g", "--game GAME", "Add top streamers for GAME") do |g|
                @options.game = g
            end

            opts.on("--highlights", "Only show highlights when fetching videos") do
                @options.highlights = true
            end

            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end

        @optparser.parse!(args)
    end

    def fetch_subs(user)
        puts "Fetching subscriptions".bold
        TwitchAPI.get_follow_data(user).map do |follow|
            follow.channel.name
        end.reverse!
    end

    def check_status
        puts "Checking streamer status...".bold
        @online = TwitchAPI.get_stream_status(@streamers)
        @online.each do |streamer, data|
            print "Getting quality options for #{streamer} "
            data.streams = Livestreamer.get_available_streams(streamer)
            clearln
        end
        @online_streamers = @online.keys.sort_by!{|s| @online[s].viewers}.reverse!
    end

    def get_archives
        puts "Requesting archives".bold
        @archives = []
        @archive_count = Hash.new(0)
        streamers.each do |streamer|
            print streamer
            vods = TwitchAPI.get_videos(
                streamer, limit: @options.limit, highlights: @options.highlights
            )
            @archives += vods
            @archive_count[streamer] += vods.to_a.size
            clearln
            puts streamer.green
        end
    end


    def banner
        @optparser.help()
    end

    def clearln
        print "\r\e[K"
    end

    def puts_streams(offset: 0)
        puts
        puts "Streams available:".bold
        index = 0

        if @options.videos
            @archives.sort_by!{|v| v.recorded_at}.reverse!
            @archives.drop(offset).take(@options.limit).each do |video|
                streamer = video.channel.display_name
                index += 1
                puts_stream_info(index, streamer, video.title.to_s, video.game.to_s, time: video.length)
            end
        else
            @online_streamers.each do |streamer|
                info = @online[streamer].channel
                streamer_name = info.display_name
                index += 1
                qualities = @online[streamer].streams
                qualities = nil if qualities.include? @options.quality
                puts_stream_info(index, streamer_name, info.status.to_s, info.game.to_s, qualities: qualities)
            end
        end
    end

    def puts_stream_info(index, streamer, title, game, qualities: nil, time: nil)
        def abbrev(str, length=77)
            short = str.chomp[0...length]
            short += "..." if str.length > 77
            short
        end
        title = abbrev(title)
        puts "#{index.to_s.bold}. #{streamer} - "\
             "#{"(#{format_time(time)}) " if time}"\
             "'#{title.sub(game, game.underline)}' "\
             "#{"playing #{game.underline}" unless title.include? game if game}"
        puts "   [ #{qualities.map{ |q|
            if q == @options.quality then q.bold else q end
        }.join(' | ')} ]" if qualities
    end

    def get_choice
        if @options.videos
            get_video_choice
        else
            get_stream_choice
        end
    end

    def get_stream_choice
        prompt = "Select stream number [and quality] to watch: ".bold
        print prompt

        loop do
            response = ($stdin.gets || "").chomp.split

            response, quality = case response.length
            when 0
                ["", nil]
            when 1
                [response[0], @options.quality]
            else
                response[0,2]
            end

            break if response.downcase == "q"

            choice = Integer(response) rescue nil
            if choice && choice > 0 && choice <= @online_streamers.length
                streamer = @online_streamers[choice - 1]
                if @online[streamer].streams.include? quality
                    launch_stream(streamer, quality)
                else
                    print "Requested quality not available, options are "
                    puts "[#{@online[streamer].streams.join(", ")}]"
                end
            else
                print "Invalid choice, try again"
            end

            #print "\r\e[A\e[K\r" + prompt
            print prompt
        end
    end

    def get_video_choice
        prompt = "Select stream number to watch: ".bold
        print prompt
        offset = 0
        streamer_offset = Hash.new{0}
        loop do
            response = $stdin.gets.chomp

            break if response.downcase == "q"
            if response == ":n" or response == ":next"
                puts "Getting next page".bold
                streamer_count = @archives.drop(offset).take(@options.limit).group_by{|v| v.channel.name}.map{|k,v| [k, v.size]}
                offset += @options.limit
                streamer_count.each do |s, o|
                    streamer_offset[s] += o
                    if streamer_offset[s] + @options.limit > @archive_count[s]
                        @archives += TwitchAPI.get_videos(
                            s, limit: o, offset: streamer_offset[s]
                        )
                        @archive_count[s] += o
                    end
                end
                puts_streams(offset: offset)
                print prompt
                next
            end

            if response == ":b" or response == ":back"
                puts "Getting previous page".bold
                streamer_count = @archives.drop(offset).take(@options.limit).group_by{|v| v.channel.name}.map{|k,v| [k, v.size]}
                streamer_count.each do |s, o|
                    streamer_offset[s] -= o
                    streamer_offset[s] = 0 if streamer_offset[s] < 0
                end
                offset -= @options.limit
                offset = 0 if offset < 0
                puts_streams(offset: offset)
                print prompt
                next
            end

            choice = Integer(response) rescue nil
            if choice && 0 < choice && choice <= 20
                stream = @archives[offset + choice - 1]
                launch_video(stream.url)
            else
                print "Invalid choice, try again"
            end

            print "\r\e[A\e[K\r" + prompt
        end
    end

    def launch_stream(streamer, quality)
        opts = @options.dup
        opts.quality = quality
        Livestreamer.start_stream(
            streamer, @options.player, opts.quality, @options.chat
        )
    end

    def launch_video(url)
        Livestreamer.start_video(url, @options.player)
    end

    def format_time(seconds)
        s = seconds % 60
        minutes = seconds / 60
        m = minutes % 60
        h = minutes / 60
        if h > 0
            "%d:%02d:%02d" % [h,m,s]
        else
            "%d:%02d" % [m,s]
        end
    end
end

