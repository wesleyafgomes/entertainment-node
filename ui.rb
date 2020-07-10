module UI

	def self.show_message(channel:, content: nil, title: nil, colour: 0x8d55cf, url: nil, description: nil, thumbnail: nil, fields: [], temporary: false, timeout: 60)
		embed = Discordrb::Webhooks::Embed.new(title: title, colour: colour, url: url, description: description, thumbnail: thumbnail, fields: fields)

		message = if temporary
			channel.send_temporary_message(content, timeout, false, embed)
		else
			channel.send_message(content, false, embed)
		end

		return message
	end

	def self.edit_message(message:, content: nil, title: nil, colour: 0x8d55cf, url: nil, description: nil, thumbnail: nil, fields: [])
		embed = Discordrb::Webhooks::Embed.new(title: title, colour: colour, url: url, description: description, thumbnail: thumbnail, fields: fields)
		return message.edit(content, embed)
	end
end
