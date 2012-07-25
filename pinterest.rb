#!/usr/bin/env ruby
require 'httpclient'
require 'nokogiri'
require 'json'

class PinterestBot
    attr_reader :client, :boards

    def initialize(email, password)
        """ Constructor

        @param :username String 
        @param :password String
        """
        @email = email
        @password = password
        @boards = {}
        @client = HTTPClient.new
    end
    
    def _get_cookie_name(cookie_name)
        """ Get value of cookie
        
        @param :res Response object of HTTPClient Request 
        @param :cookie_name String name of cookie we want to get value 
        @return String value of cookie
        """
        @client.cookies.each do |cookie|
            return cookie.value if cookie.name == cookie_name
        end
    end
    
    def get_csrftoken()
        @client.cookies.each do |cookie|
            return cookie.value if cookie.name == "csrftoken"
        end
    end

    def login()
        """ Login to pinterest

        This function should be called after initialize
        """
        @client.get "https://pinterest.com/login/"
        body =  {
            :email => @email,
            :password => @password,
            :csrfmiddlewaretoken => self.get_csrftoken()
        }
        res = @client.post "https://pinterest.com/login/", body
        self._get_list_board()
    end
    
    def _get_list_board()
        res = @client.get "https://pinterest.com/me/"

        url = res.headers["Location"]
        url = url[0..-2] if url[-1] == '/'
        @username = url[(url.rindex('/') + 1)..-1]

        res = @client.get "http://pinterest.com/#{@username}/"
        soup = Nokogiri::HTML(res.content)
        div_boards = soup.css("div[class=\"pin pinBoard\"]")
        div_boards.each do |board|
            board_name = board.css("a")[0].content
            board_id = board["id"][5..-1]
            @boards[board_name] = board_id
        end
    end

    def get_board_id_for_name(category_name)
        if not @boards.include?(category_name) then
            self.create_new_category(category_name)
        end
        @boards[category_name]
    end

    def create_new_category(category_name)
        """ Create new category

        @param :category_name String
        @return Dictionary object which contains
            :url String ULR of new category
            :status String :success is expected
            :name String `category_name`
            :id String ID of new category
        """
        puts "Create new category"
        headers = {
            "X-CSRFToken" => self.get_csrftoken(),
            "X-Pinterest-Referrer" => "http://pinterest.com/",
            "X-Requested-With" => "XMLHttpRequest",
            "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11"
        }
        body = {
            :name => category_name,
            :pass_category => true,
        }  
        res = @client.post "https://pinterest.com/board/create/", body, headers
        @boards[category_name] = JSON.parse(res.content)[:id]
    end
    

    def upload(category, description, photo_path)
        """ Upload photo to pinterest

        @param :data Dictionary which contains
            :description String
            :photo_path String path of photo in machine
            :category Category name you want to put new photo in
        """
        index = photo_path.rindex('/')
        if index
            filename = photo_path[(index + 1)..-1]
        else
            filename = photo_path
        end 

        File.open(photo_path) do |file|
            body = {
                "csrfmiddlewaretoken" => self.get_csrftoken(),
                "board" => self.get_board_id_for_name(category),
                "details" => description,
                "link" => "",
                "img_url" => "",
                "tags" => "",
                "replies" => "",
                "buyable" => "",
                "img" => file
            }
            res = @client.post "http://pinterest.com/pin/create/", body
            return res
        end
    end
end

def test()
    bot = PinterestBot.new('knt.code@gmail.com', '@123456@')
    bot.login()
    res = bot.upload("knt-test", "Description", "/DATA/Dropbox/MacImage/IMG_0167.JPG")
end

test()
