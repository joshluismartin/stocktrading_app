require "uri"
require "net/http"
require "json"

class AlphaVantage
  BASE_URL = "https://alpha-vantage.p.rapidapi.com/query"

  def self.get_stock_price(symbol)
    url = URI("#{BASE_URL}?datatype=json&output_size=compact&interval=5min&function=TIME_SERIES_INTRADAY&symbol=#{symbol}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-key"] = ENV["RAPIDAPI_KEY"]
    request["x-rapidapi-host"] = "alpha-vantage.p.rapidapi.com"

    response = http.request(request)
   
    if response.code == "200"
      JSON.parse(response.body)
    else
      { "error" => "API request failed with code #{response.code}" }
    end
  end
end

