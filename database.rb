require 'sequel'
# Dependencies
# => Sequel

module Database
	@connection = Sequel.connect(DATABASE)

	def self.do
		return @connection
	end

	module Search

		def self.write(ids:, query:)
			puts "#{LOG_DELIMITER}Starting writing process of query to database:\nNumber of entries: #{ids.length}"
			ids.each do |id|
				begin
					if Database.do[:search].where(query: query, id: id).all != []
						puts "\t>>>ID \"#{id}\" already saved. Skipping query save process for song<<<"
					else
						puts "\tQuery: INSERT INTO *search*\t VALUES (query: #{query}, id: #{id})\n"
						Database.do[:search].insert(query: query, id: id)
					end
				end
			end
		end

		def self.read(query:, max_results:)
			puts LOG_DELIMITER
			puts "Starting reading process of query from database:\nNumber of entries expected: #{max_results}\n"

			puts "\tQuery: GET *id* \t FROM TABLE *search* \t WHERE *query* = #{query}\n"

			ids = Database.do[:search].where(query: query).limit(max_results).map(:id)

			if (ids.length < max_results)
				puts "\tFound #{ids.length} result(s), expected #{max_results}. Canceling reading process.\n"#{LOG_DELIMITER}"
				return ''
			end

			print "\t\tResult: #{ids}\n"
			result = ''
			ids.each do |id|
				result += ',' if(result != '')
				result += id
			end
			#puts LOG_DELIMITER
			return result
		end
	end

	##
	# This module handles the I/O operations to the 'Song' sql table
	module Song
		def self.write(songs:)
			puts "#{LOG_DELIMITER}Starting writing process of songs to database:\nNumber of entries: #{songs.length}"
			songs.each do |song|
				begin
					puts "\tQuery: INSERT INTO *song*\t VALUES (data: #{song.to_hash.to_s})\n"
					Database.do[:song].insert(song.to_hash)
				rescue Sequel::UniqueConstraintViolation => e
					puts "\t\t>>> Error: UniqueConstraintViolation || A song with such id has already been saved <<<<"
				end
			end
		end

		def self.read(ids:) #ids: string of ids, separated by commas
			puts "#{LOG_DELIMITER}Starting reading process of song from database:\nNumber of entries expected: #{ids.length}"
			puts "\tQuery: GET *ALL* \t FROM TABLE *song* \t WHERE *id* = #{ids.to_s}\n"
			results = Database.do[:song].where(id: ids).limit(ids.length).all
			puts "\t\tResults:"
			results.map! do |result|
				puts "\t\t#{result.to_s}"
				Youtube::API::Video.new(id: result[:id], title: result[:title], author: result[:author], duration: result[:duration], downloaded: result[:downloaded])
			end
			return results
		end

		def self.update(id:,downloaded:true)
			puts "#{LOG_DELIMITER}Starting updating process of song to database:"
			puts "\tQuery: UPDATE *song*\tWHERE *id* = #{id}\tSET downloaded = #{downloaded}\n"
			# IMPLEMENT TRY-CATCH
				puts "Number of affected rows: #{Database.do[:song].where(id: id).update(downloaded: downloaded)}\n"
			#
		end

	end
end
