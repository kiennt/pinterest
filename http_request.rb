require 'httpclient'

class WebAgent
  class CookieManager
    # Public: Load cookies from a string
    # 
    # cookie - String which includes many lines each line has format
    #   <url>  <name> <value> <expires> <domain> <path> <flag> 
    # NOTE: This function was part of CookieManager.load_cookies   
    def load_cookies_from_string(cookie_str)
      @cookies.synchronize do
        @cookies.clear
        cookie_str.split("\n").each do |line|
          cookie = WebAgent::Cookie.new()
          @cookies << cookie
          col = line.chomp.split(/\t/)
          puts col
          cookie.url = URI.parse(col[0])
          cookie.name = col[1]
          cookie.value = col[2]
          if col[3].empty? or col[3] == '0'
            cookie.expires = nil
          else
            cookie.expires = Time.at(col[3].to_i).gmtime
          end
          cookie.domain = col[4]
          cookie.path = col[5]
          cookie.set_flag(col[6])
        end
      end
    end
  
    # Public: Get string of cookies
    # 
    # Return String represent for current cookies
    def get_cookies_str
      @cookies.synchronize do
        list_cookies = []
        @cookies.each do |cookie|
          if cookie.use? && !cookie.discard?
            list_cookies << [cookie.url.to_s,
                             cookie.name,
                             cookie.value,
                             cookie.expires.to_i,
                             cookie.domain,
                             cookie.path,
                             cookie.flag].join("\t")
          end
        end
        list_cookies.join("\n")
      end
    end 
  end

end


class HTTPRequest
  attr_reader :client 
  attr_accessor :debug
  
  # Public: Constructor
  def initialize
    @debug = false
    @client = HTTPClient.new

    # fake User-Agent
    @headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11"
    }
  end
  
  # Private: Make request   
  #
  # method - String in GET, POST, PUT, DELETE
  # url - String URL to make request
  # data - Dictionary payload data POST to server 
  # headers - Dictionary customize
  # 
  # Return Response object
  def _make_request(method, url, data, headers = nil) 
    # update headers with default value
    headers = {} unless headers
    headers.update @headers
    
    if @debug
      puts "-----------------------------------"
      puts "Make #{method} request to #{url}"
      puts "Headers"
      headers.each do |key, value|
        puts "  #{key}: #{value}"
      end
      puts "Payload"
      data.each do |key, value|
        puts "  #{key}: #{value}"
      end
      puts "-----------------------------------"
    end 

    # make request
    case method
    when "GET" then @client.get url, headers
    when "POST" then @client.post url, data, headers
    when "PUT" then @client.put url, headers
    when "DELETE" then @client.delete url, headers
    end
  end
  
  # Public: Wrapper for `_make_request`
  def get(url, header = nil)
    _make_request "GET", url, nil, header
  end

  # Public: Wrapper for `_make_request`
  def post(url, data, header = nil)
    _make_request "POST", url, data, header
  end

  # Public: Wrapper for `_make_request`
  def put(url, header = nil)
    _make_request "PUT", url, nil, header
  end

  # Public: Wrapper for `_make_request`
  def delete(url, header = nil)
    _make_request "DELETE", url, nil, header
  end

  # Private: Get value of cookie
  # 
  # res - Response object of HTTPClient Request 
  # cookie_name - String name of cookie we want to get value 
  #   
  # Return a String value of cookie
  def _get_cookie_name(cookie_name)
    @client.cookies.each do |cookie|
      return cookie.value if cookie.name == cookie_name
    end
  end
    
end
