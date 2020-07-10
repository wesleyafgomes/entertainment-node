require_relative 'config.rb'
require_relative 'server.rb'
require_relative 'ffmpeg_fix.rb'

$bot = Discordrb::Commands::CommandBot.new token: DISCORD_API_TOKEN, client_id: DISCORD_API_CLIENT_ID, prefix: COMMAND_IDENTIFIER, channels: [CHANNEL] # node
$servers = {}

# Command that connect the bot to a voice channel. Additionaly adds a server to the $server, if it's not already registered
# Displays an error if the caller is not connected to a voice channel
$bot.command(:connect) do |event|
  if $servers[event.server.id].nil?
    serverbot = Server.new(event)
    if serverbot.voice.nil?
      UI.show_message(channel: event.channel, title: ERROR_TITLE, description: "You are not connected to a voice channel.\nPlease connect and try again.", thumbnail: ERROR_ICON)
    else
      $servers[event.server.id] = serverbot
    end

  else
    $servers[event.server.id].connect(event)
  end

  return nil
end

# The below commands displays an error if the bot is not connected to a voice channel

# Searches and adds a song to the bot playlist.
$bot.command(:add) do |event, *args|
  next UI.show_message(channel: event.channel, title: ERROR_TITLE, description: NOT_CONNECTED_ERR, thumbnail: ERROR_ICON, temporary: true) if $servers[event.server.id].nil?

  query = args.join(' ')

  msg = UI.show_message(channel: event.channel, title: "Searching for", description: query)
  search = Youtube::API.search(query: query)

  video = search[0]

  if ($servers[event.server.id].addToPlaylist(video))
    UI.edit_message(message: msg, title: "Song added to the playlist!", description: video.title)
  else
    UI.edit_message(message: msg, title: ERROR_TITLE, description: "Unable to add #{video.title} to the playlist", thumbnail: ERROR_ICON)
  end

  return nil
end

# Starts the playback of the playlist
$bot.command(:play) do |event|
  next UI.show_message(channel: event.channel, title: ERROR_TITLE, description: NOT_CONNECTED_ERR, thumbnail: ERROR_ICON, temporary: true) if $servers[event.server.id].nil?
  $servers[event.server.id].play

  return nil
end

# Stops the playback
$bot.command(:stop) do |event|
  next UI.show_message(channel: event.channel, title: ERROR_TITLE, description: NOT_CONNECTED_ERR, thumbnail: ERROR_ICON, temporary: true) if $servers[event.server.id].nil?
  $servers[event.server.id].stop()

  return nil
end

# Pauses the playback
$bot.command(:pause) do |event|
  next UI.show_message(channel: event.channel, title: ERROR_TITLE, description: NOT_CONNECTED_ERR, thumbnail: ERROR_ICON, temporary: true) if $servers[event.server.id].nil?
  $servers[event.server.id].pause()

  return nil
end

# Skips to the +to+ song in the playlist, or to the next if no value is passed to it
$bot.command(:skip) do |event, to|
  next UI.show_message(channel: event.channel, title: ERROR_TITLE, description: NOT_CONNECTED_ERR, thumbnail: ERROR_ICON, temporary: true) if $servers[event.server.id].nil?

  to = to.to_i - 1 unless to.nil? # UI shows lists starting from 1. Arrays start at 0.

  $servers[event.server.id].skip(to)

  return nil
end

# TODO: playlist
$bot.command(:playlist) do |event|
  UI.show_message(channel: event.channel)
end

# TODO: delete

# TODO: clear

# TODO: disconnect

$bot.run
