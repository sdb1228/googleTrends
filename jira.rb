# encoding: utf-8
require 'net/http'
require "open-uri"
require 'nokogiri'
require 'rubygems'
require 'json'
require 'eventmachine'
require 'faye/websocket'

class Jira
	def self.two_n

		uri = URI.parse("https://slack.com/api/rtm.start")
		args = {token: 'TOKEN'}
		uri.query = URI.encode_www_form(args)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		request = Net::HTTP::Get.new(uri.request_uri)

		response = http.request(request)
		parsed = JSON.parse(response.body)
		uri2 = parsed["url"]

		EM.run {
			ws = Faye::WebSocket::Client.new(uri2.to_s)

			ws.on :open do |event|
				puts [:open]
			end

			ws.on :message do |event|
				data = JSON.parse(event.data)
				type = data["type"]
				if type.eql? "message" and data["text"].eql? "give me google trends"
					url = 'http://www.google.com/trends/hottrends/atom/feed?pn=p1'
					uri = URI.parse(URI.encode(url.strip))
					http = Net::HTTP.new(uri.host, uri.port)
					@data = http.get(uri.request_uri)
					doc =  Nokogiri::XML(@data.body)
					channel = data["channel"]
					count = 1
					trend = ""
					doc.xpath('//item	').each do |thing|
						trend << count.to_s
						trend << " "
						trend << thing.at_xpath('title').content
						trend << " "
						trend << thing.at_xpath('ht:news_item//ht:news_item_url').content
						trend <<"\n"
						count+= 1
					end
					args = {token: 'TOKEN', channel: channel, text: trend, username:'Google bot', icon_url:'http://i.forbesimg.com/media/lists/companies/google_416x416.jpg'}
					botUri = URI.parse("https://slack.com/api/chat.postMessage")
					botUri.query = URI.encode_www_form(args)
					http = Net::HTTP.new(botUri.host, botUri.port)
					http.use_ssl = true
					request = Net::HTTP::Get.new(botUri.request_uri)
					response = http.request(request)
				end

			end

			ws.on :close do |event|
				puts [:close, event.code, event.reason]
				puts event.reason
				ws = nil
			end
		}

	end
end



# Things that may be needed

# puts "ID   = " + thing.at_xpath('title').content
# puts "Name = " + thing.at_xpath('link').content
