require 'rest_client'
require 'json'

require_relative 'database'
require_relative 'config'

module Youtube
	module API
		class Video
			attr_reader :id
			attr_reader :title
			attr_reader :author
			attr_reader :duration
			attr_reader :downloaded

			def initialize(id:, title:, author:, duration:, downloaded: false)
				@id = id
				@title = title
				@author = author
				@duration = duration
				@downloaded = downloaded
			end

			def to_hash()
				return {
					id: 		@id,
					title:		@title,
					author:		@author,
					duration:	@duration,
					downloaded:	@downloaded
				}
			end

			def download()
				Youtube::API.download(song: self)
			end
		end

		def self.search(query:, max_results: 1)
			ids = Database::Search.read(query: query, max_results: max_results)
			if(ids == '')
				#begin
					puts "#{LOG_DELIMITER}Sending Youtube API request: GET *id*\tFROM *search*\tWHERE *query* = \"#{query}\"\n"
					result = JSON.parse(RestClient.get(
						"#{YOUTUBE_API_URL}/search?part=snippet&maxResults=#{max_results}&q=#{query}&fields=items%2Fid%2FvideoId&key=#{YOUTUBE_API_KEY}"
					)) # Youtube API returns a string containing all ids, separated by ','
				#rescue RestClient::TooManyRequests => e

				#	retry
				#end

				result["items"].each do |item|
					ids += ',' if(ids != '')
					ids += item['id']['videoId']
				end
				puts "\tResponse: #{ids.split(',')}\n"#{LOG_DELIMITER}"
				Database::Search.write(ids: ids.split(','), query: query)
			end

			return self.getInfo(ids: ids)
		end

		def self.getInfo(ids:)
			result = Database::Song.read(ids: ids)
			if(result == [])
				song_list = []
				# REQUEST, IMPLEMENT A TRY CATCH!!!!!!!!!!!
					puts "#{LOG_DELIMITER}Sending Youtube API request: GET *ALL*\tFROM *videos*\tWHERE *id* = \"#{ids}\"\n"
					result = JSON.parse(RestClient.get(
							"#{YOUTUBE_API_URL}/videos?part=snippet%2C+contentDetails&id=#{ids}&fields=items(contentDetails%2Fduration%2Cid%2Csnippet(channelTitle%2Ctitle))&key=#{YOUTUBE_API_KEY}"
					))
				i=1
				result["items"].each do |item|
					puts "\tResponse #{i}/#{ids.split(',').length}: {id: #{item['id']}, title: #{item['snippet']['title']}, author: #{item['snippet']['channelTitle']}, duration: #{interpretISO8601(item['contentDetails']['duration'])}}\n"
					song_list.push(Video.new(id: item['id'], title: item['snippet']['title'], author: item['snippet']['channelTitle'], duration: interpretISO8601(item['contentDetails']['duration'])))
					i+=1
				end
				#puts LOG_DELIMITER
				Database::Song.write(songs: song_list)
				return song_list
			end
			return result
		end

		def self.download(song:)
			if(song.downloaded == false)
				puts "#{LOG_DELIMITER}Initiating download of song with ID = #{song.id}\n"
				success = system("youtube-dl -q --no-playlist -x --audio-format \"mp3\" -o \"/#{MUSIC_FOLDER}%(id)s.%(ext)s\" https://www.youtube.com/watch?v=#{song.id}")
				#puts LOG_DELIMITER

				Database::Song.update(id: song.id) if success
				return success
			end
			return true
		end

		private
		def self.interpretISO8601(iso)
			raise ArgumentError, 'Argument is not a ISO8601 string' if(iso[0] != 'P') #PT5M21S
			seconds = 0
			numstr = ''
			multiplier = 0
			iso.each_char do |char|
				case(char)
					when 'P', 'T'
						next
					when 'H'
						multiplier = 60*60
					when 'M'
						multiplier = 60
					when 'S'
						multiplier = 1
					else
						numstr += char; multiplier = 0
				end
				if (multiplier != 0)
					seconds += numstr.to_i * multiplier
					numstr = ''
				end
			end
			return seconds
		end
	end

end
