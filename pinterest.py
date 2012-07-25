#!/usr/bin/env python

import requests
from bs4 import BeautifulSoup
import logging

class PinterestBot(object):
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.cookies = {}
        self.boards = {}
        self.headers = {
            "Accept" : "*/*",
            "Accept-Charset" : "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
            "Accept-Encoding" : "gzip,deflate,sdch",
            "Accept-Language" : "en-US,en;q=0.8",
            "Connection" : "keep-alive",
            "Content-Type" : "application/x-www-form-urlencoded; charset=UTF-8",
            "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11",
            "X-Requested-With" : "XMLHttpRequest", 
        }
        self.logger = logging.getLogger("")
        self.logger.addHandler(logging.StreamHandler())
   
    def _get_request_info(self, method, url, data=None):
        """Return string represent for the request"""
        info  = "Method %s\n" % method
        info += "URL: %s\n" % url
        info += "Cookies: \n"
        for k, v in self.cookies.items():
            info += "    %s: %s\n" % (k, v)
        if data:
            info += "Payload: \n"
            for k, v in data.items():
                info += "    %s: %s\n" % (k, v)
        return info

    def _make_request(self, method, url, data=None, headers=None):
        """Make request to server. If request sucessful, apply cookie to new request
        
        @return :class: Request object   
        """
        if not data: data = {}
        res = None
        try:
            if method == "GET":
                res = requests.get(url, cookies=self.cookies)
            elif method == "POST":
                if headers == None:
                    res = requests.post(url, data, cookies=self.cookies) 
                else:
                    res = requests.post(url, data, cookies=self.cookies, headers=headers)
            elif method == "PUT":
                res = requests.put(url, data, cookies=self.cookies) 

        except Exception as e:
            self.logger.error("--------------------------------------")
            self.logger.error("Cannot make request to %s" % url)
            self.logger.error(self._get_request_info(method, url, data))
            raise e

        if not res.ok:
            self.logger.error("--------------------------------------")
            self.logger.error("Request cannot get good respons to %s" % url)
            self.logger.error(self._get_request_info(method, url, data))
            self.logger.error("Response: ")
            self.logger.error(res.content)
        
        for k, v in res.cookies.items():
            self.cookies[k] = v
        return res
    
    def get(self, url):
        """Wrapper for :_make_request function"""
        return self._make_request("GET", url)

    def post(self, url, data=None, headers=None):
        """Wrapper for :_make_request function"""
        if headers == None:
            return self._make_request("POST", url, data=data)
        else:
            return self._make_request("POST", url, data=data, headers=headers)

    def put(self, url, data=None):
        """Wrapper for :_make_request function"""
        return self._make_request("PUT", url, data=data)

    def login(self):
        self.get("https://pinterest.com/login/")
        token = self.cookies["csrftoken"]
        self.post("https://pinterest.com/login/", data = {
            "email" : self.username,
            "password" : self.password,
            "csrfmiddlewaretoken" : token        
        })
        self._get_list_boards()
    
    def _get_list_boards(self):
        soup = BeautifulSoup(self.get("https://pinterest.com/me").content)              
        div_boards = soup.find_all("div", {"class" : "pin pinBoard"})
        for board in div_boards:
            board_name = board.find("a").contents[0].encode("utf-8").strip()
            board_id = board.attrs["id"][5:]
            self.boards[board_name] = board_id

    def create_category(self, category_name):
        if category_name in self.boards:
            print "Category %s already created" % category_name
            return

        data = {
            "name" : category_name,
        }
        headers = {
            "X-CSRFToken" : self.cookies["csrftoken"],
            "X-Pinterest-Referrer" : "http://pinterest.com/",
            "X-Requested-With" : "XMLHttpRequest",
            "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11"
        }
        res = self.post("https://pinterest.com/board/create/", data=data, headers=headers)
        board_id = res.json["id"]
        self.boards[category_name] = board_id
        return res.json
    
    def get_board_id(self, category_name):
        if category_name not in self.boards:
            self.create_category(category_name)
        return self.boards[category_name]

    def upload(self, category_name, description, photo_path):
        data = {
            "board" : self.get_board_id(category_name),
            "details" : description, 
            "link" : "",
            "tags" : "",
            "buyable" : "",
            "img_url" : "",
            "csrfmiddlewaretoken" : self.cookies["csrftoken"],
            "img" : open(photo_path)
        }
        res = self.post("http://pinterests.com/pin/create/", data=data)
        return res

if __name__ == "__main__":
    bot = PinterestBot("knt.code@gmail.com", "@123456@")
    bot.login()
    res = bot.upload("test new", "My description", "/DATA/Dropbox/MacImage/IMG_0167.JPG")
    print res.headers
