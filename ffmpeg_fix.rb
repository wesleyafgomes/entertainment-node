# frozen_string_literal: true

require 'discordrb'
require 'discordrb/voice/encoder'
require 'discordrb/voice/network'
require 'discordrb/logger'

# Voice support
module Discordrb::Voice
  class VoiceBot
    def play(encoded_io)
      stop_playing(true) if @playing
      @retry_attempts = 3
      @first_packet = true

      play_internal do
        buf = nil

        # Read some data from the buffer
        begin
          buf = encoded_io.readpartial(DATA_LENGTH) if encoded_io
        rescue EOFError
          raise IOError, 'File or stream not found!' if @first_packet

          @bot.debug('EOF while reading, breaking immediately')
          next :stop
        end

        # Check whether the buffer has enough data
        if !buf || buf.length != DATA_LENGTH
          @bot.debug("No data is available! Retrying #{@retry_attempts} more times")
          next :stop if @retry_attempts.zero?

          @retry_attempts -= 1
          next
        end

        # Adjust volume
        buf = @encoder.adjust_volume(buf, @volume) if @volume != 1.0

        @first_packet = false

        # Encode data
        @encoder.encode(buf)
      end

      # If the stream is a process, kill it
      if encoded_io.respond_to? :pid
        Discordrb::LOGGER.debug("Killing ffmpeg process with pid #{encoded_io.pid.inspect}")

        begin
          Process.kill(0, encoded_io.pid)
        rescue => e
          Discordrb::LOGGER.warn('Failed to kill ffmpeg process! You *might* have a process leak now.')
          Discordrb::LOGGER.warn("Reason: #{e}")
        end
      end

      # Close the stream
      encoded_io.close
    end
  end
end
