#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'kconv'

# 普通にアクセス
#http = Net::HTTP.new('172.31.11.150', 8080)
#response = http.post('/webtops2/', 'ei=UTF-8&p=test')
#p response.body

# 普通にログイン
uri  = URI.parse('http://172.31.11.150')
http = Net::HTTP.new(uri.host, 8080)

# 一度アクセスして発行されるクッキーｗ取得しておく
response = http.get('/webtops2/')
cookie = ''
response.each do |name,value|
  if name == 'set-cookie' then
    cookie = value
  end
end

# HTTP ヘッダの設定(Burpで入手したヘッダーの値をそのまま記述(クッキーだけは上記で取得したの))
req = Net::HTTP::Post.new('/webtops2/j_security_check')
req["Cookie"]          = cookie
req["User-Agent"]      = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:55.0) Gecko/20100101 Firefox/55.0"
req["Accept"]          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
req["Accept-Language"] = "ja,en-US;q=0.7,en;q=0.3"
req["Referer"]         = "http://172.31.11.150:8080/webtops2/"
req["Upgrade-Insecure-Requests"] = "1"
req.body = 'j_username=44902&j_password=KN500630&logon=%83%8D%83O%83C%83%93'

# 接続
res = http.request(req)

# 戻り値の検証を行う
puts "code -> #{res.code}"
puts "msg -> #{res.message}"
#puts "body -> #{Kconv.tosjis(res.body)}"

# Proxy経由でアクセス
#proxy_class = Net::HTTP::Proxy('proxy.center.kawamura.co.jp', 80)
#http = proxy_class.new('nobus-juice-shop.herokuapp.com')
#response = http.post('/#/login', '"email":"abcdefg","password":"12345"')
#p response.body

# HTTP Head を キー：バリュー で表示する
#puts Net::HTTP.get_response(URI.parse(site.uri)).code
#response.each do |name,value|
#  puts name + ' : ' + value
#end

# HTTPレスポンスのステータスコードやヘッダも見たい
#url = URI.parse('http://172.31.11.150')
#res = Net::HTTP.start(url.host, 8080) do |http|
#  http.post('/webtops2/technoban/constmanagesys/estimatesrequestlist.do', 'j_username=abcde&j_password=123456&logon=%83%8D%83O%83C%83%93')
#end
#puts res.code
#puts Kconv.tosjis(res.body)

# Proxy経由でHTTPレスポンスのステータスコードやヘッダも見たい
#url = URI.parse('http://nobus-juice-shop.herokuapp.com')
#proxy_class = Net::HTTP::Proxy('proxy.center.kawamura.co.jp', 80)
#res = proxy_class.start(url.host, url.port) do |http|
#  http.post('/#/login', '"email":"abcdefg","password":"12345"')
#end
#puts res.code
#puts Kconv.tosjis(res.body)
