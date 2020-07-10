require_relative 'ui.rb'
require_relative 'youtube.rb'

class Server
  attr_reader :channel
  attr_reader :voice

  attr_reader :playlist
  attr_reader :playlistIndex
  attr_accessor :repeat

  def initialize(event)
    @channel = event.channel;
    if (event.user.voice_channel)
      @voice = $bot.voice_connect(event.user.voice_channel);
    else
      @voice = nil
    end

    @playlist = []
    @playlistIndex = 0
    @repeat = false

    @break_play_loop = false
    @paused = false
  end

  def connect(event)
    return false if @voice.playing?
    @voice = $bot.voice_connect(event.user.voice_channel);
    return true
  end

  def quit() # TODO: MAKE THIS WORK
    #@voice.destroy
  end

  def addToPlaylist(video)
    unless (video.downloaded)
      puts(LOG_DELIMITER)
      puts("=========File not Downloaded=========\n")
      puts("ID: #{video.id}\tTitle: #{video.title}\n")
      puts(LOG_DELIMITER)

      video.download()
    end
    @playlist.push(video)
    return true
  end

  def deleteFromPlaylist(index)
    return false if index == @playlistIndex

    @playlist[index] = nil
    @playlist.compact!

    return true
  end

  def clearPlaylist()
    return false if @voice.playing?
  end

  def play()
    return false if @voice.playing? && @paused == false

    if @paused
      self.voice.continue()
      @paused = false
      return true
    end

    loop do
      while(@playlistIndex < @playlist.length && @break_play_loop == false)
        video = @playlist[@playlistIndex]
        UI.show_message(channel: @channel, title: "Now playing:", description: video.title, temporary: true, timeout: video.duration)
        self.voice.play_file("#{MUSIC_FOLDER}#{video.id}.mp3")
        @playlistIndex += 1
      end
      break if (@break_play_loop || @repeat == false)
    end

    @break_play_loop = false
    @paused = false
    @playlistIndex = 0

    return true
  end

  def stop()
    return false unless @voice.playing?
    @break_play_loop = true
    @voice.stop_playing(true)

    return true
  end

  def skip(to)
    to = @playlistIndex + 1 if to.nil?

    return false if (to < 0 || to >= @playlist.length)
    @voice.stop_playing(true)

    return true
  end

  def pause()
    return false unless @voice.playing? && @paused == false
    @voice.pause
    @paused = true
    return true
  end
end
