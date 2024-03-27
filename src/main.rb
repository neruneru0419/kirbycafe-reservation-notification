require 'selenium-webdriver'
require "date"
require "line_notify"

YOUR_LINE_TOKEN = ENV["LINE_TOKEN"]

def find_all_char_indices(string, char)
  indices = []
  string.chars.each_with_index do |c, index|
    indices.push(index + 1) if c == char
  end
  indices
end

def get_reservation_status(date_string, reservation_string)
  match_data = date_string.match(/(\d+)年(\d+)月/)
  year = match_data[1].to_i
  month = match_data[2].to_i

  reservation_string.gsub!(/[\r\n]/,"")
  p reservation_string
  matches = reservation_string.scan(/(\d{2}:\d{2})([^0-9]*[^\d:]+)/)
  reservation = []

  matches.each do |match|
    reservation_time = match[0]
    reservation_status = find_all_char_indices(match[1], "○")
    unless reservation_status.empty?
      reservation_status.each do |day|
          reservation.push({
              "year" => year,
              "month" => month,
              "day" => day,
              "time" => reservation_time
          })
      end
    end
  end

  reservation
end

def kirby_cafe_line_notify(reservation_status)
  line_notify = LineNotify.new(YOUR_LINE_TOKEN)
  message = "現在、以下の日時で予約できます。\n\n"

  reservation_status.each do |rs|
    year = rs["year"]
    month = rs["month"]
    day = rs["day"]
    time = rs["time"]
    weekday = case Date.new(year, month, day).wday
      when 0 then "日曜日"
      when 1 then "月曜日"
      when 2 then "火曜日"
      when 3 then "水曜日"
      when 4 then "木曜日"
      when 5 then "金曜日"
      when 6 then "土曜日"
    end

    message += "#{month}月#{day}日(#{weekday}) #{time}\n"
  end
  message += "https://kirbycafe-reserve.com/guest/tokyo/reserve/"
  options = { message: message }
  line_notify.ping(options)
end

session = Selenium::WebDriver.for :chrome
wait = Selenium::WebDriver::Wait.new(:timeout => 10)

session.manage.timeouts.page_load = 5
session.get "https://kirbycafe-reserve.com/guest/tokyo/reserve/"
sleep(3)

loop do
  begin
    session.find_element(:class_name,'v-btn').click
    session.find_element(:class_name,'v-select__slot').click
    session.find_element(:class_name,'v-list-item__content').click
    date_string = session.find_element(:class_name, 'body-1')
    sleep(1)
    reservation_string = session.find_element(:tag_name, 'tbody')
  rescue
    session.navigate.refresh
    sleep(3)
    retry
  end

  reservation_status = get_reservation_status(date_string.text, reservation_string.text)

  unless reservation_status.empty?
    kirby_cafe_line_notify(reservation_status)
  end

  p reservation_status
  sleep(60)
  session.navigate.refresh
  sleep(3)
end

session.quit
