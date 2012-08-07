require File.join(File.dirname(__FILE__), "/../pinterest")

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

describe PinterestBot, :test_login do 
  it "logins failed" do
    begin
      bot = PinterestBot.new("thangmeo2020@gmail.com", "@123456@")
      bot.login
    rescue Exception => e
      e.message.should == "Login failed" 
    end
  end

  it "logins success" do
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
  end
end

describe PinterestBot, :test_activies do

  it "gets username" do
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
    bot.username.should == "thangmeo2020"
  end

  it "creates new board" do
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
    board_name = "board#{Time.now.to_i}"
    res = bot.create_new_board board_name
    res["status"].should == "success"
    bot.boards.should have_key board_name
  end
  
  it "deletes a board" do 
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
    bot.boards.each do |name, board_id|
      res = bot.delete_board name  
      res["status"].should == "done"
    end
  end

  it "uploads image to board" do
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
    res = bot.create_pin({
      :board => "test", 
      :caption => "Description at #{Time.new}", 
      :path => "/DATA/Dropbox/MacImage/IMG_0167.JPG"
    })
    res["status"].should == "success"
    res["message"].should == "posted."
  end

  it "update avatar" do
    bot = PinterestBot.new "knt.code@gmail.com", "@123456@"
    bot.login
    res = bot.update_avatar "/DATA/PERSONAL/avatar.jpg"
    res.to_s.should == "test"
  end
end
