require 'httpclient'
require 'nokogiri'
require 'json'

class PinterestBot
    # Constructor
    #
    # username - String  
    # password - String
    def initialize(email, password)
        @email = email
        @password = password
        @client = HTTPClient.new
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
    
    # Public: Get csrf token from cookies
    # 
    # Return a String value of csrf token
    def csrftoken
        _get_cookie_name "csrftoken"
    end
    
    # Public: Login to pinterest with authenticate information
    # This function should be called after initialize
    # 
    # Example
    #   bot = PinterestBot(email, password)
    #   bot.login()
    def login
        @client.get "https://pinterest.com/login/"
        body = {
            :email => @email,
            :password => @password,
            :csrfmiddlewaretoken => csrftoken
        }
        res = @client.post "https://pinterest.com/login/", body
    end
   
    # Public: Get username of this user
    #
    # Return a String    
    def username 
        return @username if @username
        
        puts "get username"
        res = @client.get "https://pinterest.com/me/"
        url = res.headers["Location"]
        url = url[0..-2] if url[-1] == '/'
        @username = url[(url.rindex('/') + 1)..-1]
    end

    # Public: Get list of board of this account
    # 
    # Return a Dictionary which 
    #   key - String board name
    #   value - String board id
    def boards
        return @boards if @boards
        
        puts "get boards"
        @boards = {}
        res = @client.get "http://pinterest.com/#{username}/"
        soup = Nokogiri::HTML(res.content)

        div_boards = soup.css("div[class=\"pin pinBoard\"]")
        div_boards.each do |board|
            name = board.css("a")[0].content
            board_id = board["id"][5..-1]
            @boards[name] = board_id
        end
        @boards
    end
    
    # Public: Create new board
    #
    # name - String name of new board
    #   
    # Return a Dictionary object which contains
    #   url - String ULR of new category
    #   status - String :success is expected
    #   name - String `category_name`
    #   id - String ID of new category
    def create_new_board(name)
        headers = {
            "X-CSRFToken" => csrftoken(),
            "X-Pinterest-Referrer" => "http://pinterest.com/",
            "X-Requested-With" => "XMLHttpRequest",
            "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11"
        }
        body = {
            :name => name,
            :pass_category => true,
        }  
        res = @client.post "https://pinterest.com/board/create/", body, headers
        JSON.parse(res.content)
    end

    # Public: Get id for board name
    # 
    # name - String name of board     
    # 
    # Return String id of board
    def get_board_id_for_name(name)
        if not boards.include?(name) then
            res = create_new_board(name)
            board_id = res[:id]
            boards[name] = board_id
        end

        boards[name]
    end

    # Public: Upload photo to pinterest
    #
    # data - Dictionary which contains
    #   :caption - String caption you want to put in image
    #   :path - String path of photo in machine
    #   :board - String name of board you want to put new photo in
    #
    # Return Dictionary which contains
    #   :status - String "success" expected
    #   :url - String with format "/pin/<pin_id>/"
    #   :message - String "posted." expected
    def create_pin(data)
        File.open(data[:path]) do |file|
            body = {
                "csrfmiddlewaretoken" => csrftoken,
                "board" => get_board_id_for_name(data[:board]),
                "details" => data[:caption],
                "link" => "",
                "img_url" => "",
                "tags" => "",
                "replies" => "",
                "buyable" => "",
                "img" => file
            }
            res = @client.post "http://pinterest.com/pin/create/", body
            res.content
        end
    end

end

bot = PinterestBot.new('knt.code@gmail.com', '@123456@')
bot.login
10.times do |i|
    res = bot.create_pin({
        :board => "knt-test2", 
        :caption => "Caption #{i}", 
        :path => "/DATA/Dropbox/MacImage/IMG_0167.JPG"
    })
    puts res
end
