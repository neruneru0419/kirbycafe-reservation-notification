# selenium-webdriverを取り込む
require 'selenium-webdriver'

# ブラウザの指定(Chrome)
session = Selenium::WebDriver.for :chrome
# 10秒待っても読み込まれない場合は、エラーが発生する
session.manage.timeouts.implicit_wait = 10
# ページ遷移する
session.get "https://kirbycafe-reserve.com/guest/tokyo/reserve/"
sleep(1)
session.find_element(:class_name,'v-btn').click
sleep(1)
session.find_element(:class_name,'v-select__slot').click
sleep(1)
session.find_element(:class_name,'v-list-item__content').click

# 5秒遅延(処理が早すぎてページ遷移前にスクリーンショットされてしまうため)
sleep(10)

# ブラウザを終了
session.quit