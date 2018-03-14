require "http/client"
require "xml"
require "kemal"

get "/" do
  urls = nil
  render "views/index.ecr"
end

post "/" do |env|
  channel = Channel(Nil).new
  input_urls = env.params.body["urls"].as(String).split("\r\n")
  urls = Array(String).new(input_urls.size, "")
  input_urls.each_with_index do |url, i|
    spawn do
      urls[i] = amazon_url(url)
      channel.send(nil)
    end
  end
  input_urls.size.times { channel.receive }
  render "views/index.ecr"
end

def amazon_url(url)
  puts "Fetching #{url}"
  response = HTTP::Client.get(url)
  puts "Parsing #{url}"
  parser = XML.parse_html(response.body)
  asin = parser.xpath("//input[@name=\"ASIN\"]").as(XML::NodeSet)[0]["value"]
  title = parser.xpath("//*[@id=\"productTitle\"]").as(XML::NodeSet)[0].content.as(String).strip
  "[#{title}](https://www.amazon.com/o/ASIN/#{asin}/parpaspod-20)"
rescue ex
  "Problem with #{url} | #{ex.message}"
end

Kemal.run
