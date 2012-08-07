require 'httpclient'
require 'nokogiri'
require 'json'
require File.join(File.dirname(__FILE__), './http_request')

class PinterestBot < HTTPRequest
  # Constructor
  #
  # username - String  
  # password - String
  def initialize(email, password)
    super()
    @email = email
    @password = password
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
  #   bot.login
  # 
  # Raise exception if login failed       
  def login
    get "https://pinterest.com/login/"
    body = {
      :email => @email,
      :password => @password,
      :csrfmiddlewaretoken => csrftoken
    }
    res = post "https://pinterest.com/login/", body
    raise "Login failed" if res.content != ""
  end
 
  # Public: Get username of this user
  #
  # Return a String    
  def username 
    return @username if @username
    
    res = get "https://pinterest.com/me/"
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
    
    @boards = {}
    res = get "http://pinterest.com/#{username}/"
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
    }
    body = {
      :name => name,
      :pass_category => true,
    }  
    res = post "https://pinterest.com/board/create/", body, headers
    JSON.parse res.content
  end
 
  # Public: Delete an board with name 
  #
  # name - String name of boards
  def delete_board(name)
    res = delete "https://pinterest.com/#{username}/#{name}/settings/"
    JSON.parse res.content
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
      res = post "http://pinterest.com/pin/create/", body
      JSON.parse res.content
    end
  end
  
  # Public: Update pinterest avatar with image from photo_path
  #
  # photo_path - String path to avatar photo
  # 
  # Return Dictionary 
  def update_avatar(photo_path)
    # first go to https://pinterest.com/settings/ to get user information
    res = get "https://pinterest.com/settings/"
    soup = Nokogiri::HTML(res.content)
    File.open(photo_path) do |file| 
      body = {
        "csrfmiddlewaretoken" => csrftoken,
        "first_name" => soup.css("input#id_first_name")[0]["value"] || "",
        "last_name" => soup.css("input#id_last_name")[0]["value"] || "",
        "language" => soup.css("select#id_language option[selected=\"selected\"]")[0]["value"],
        "username" => soup.css("input#id_username")[0]["value"],
        "gender" => soup.css("input[name=\"gender\"][checked=\"checked\"]")[0]["value"],
        "about" => soup.css("textarea#id_about")[0].content,
        "location" => soup.css("input#id_location")[0]["value"] || "",
        "website" => soup.css("input#id_website")[0]["value"] || "",
        "img" => file,
      }
      res = post "https://pinterest.com/settings/"
      res.content
    end
  end

end
