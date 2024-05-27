require 'csv'
require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def collect_all_stats(report, users_objects)
  users_objects.each do |user|
    user_key = "#{user.attributes[2]} #{user.attributes[3]}"
    sessions = user.sessions
    browsers = sessions.map { |s| s[3].upcase }
    total_time = sessions.sum { |s| s[4].to_i }
    longest_session = sessions.max_by { |s| s[4].to_i }[4].to_i
    used_ie = browsers.any? { |b| b.include?('INTERNET EXPLORER') }
    always_used_chrome = browsers.all? { |b| b.include?('CHROME') }
    dates = sessions.map { |s| Date.parse(s[5]) }.sort.reverse.map(&:iso8601)

    report['usersStats'][user_key] = {
      'sessionsCount' => sessions.count,
      'totalTime' => "#{total_time} min.",
      'longestSession' => "#{longest_session} min.",
      'browsers' => browsers.sort.join(', '),
      'usedIE' => used_ie,
      'alwaysUsedChrome' => always_used_chrome,
      'dates' => dates
    }
  end
end

def work
  users = []
  sessions_by_user = Hash.new { |hash, key| hash[key] = [] }

  CSV.foreach('data_large.txt', headers: false) do |row|
    if row[0] == 'user'
      users << row
    elsif row[0] == 'session'
      sessions_by_user[row[1]] << row
    end
  end

  report = {}
  report[:totalUsers] = users.count

  unique_browsers = sessions_by_user.values.flatten(1).map { |s| s[3] }.uniq
  report['uniqueBrowsersCount'] = unique_browsers.count

  total_sessions = sessions_by_user.values.flatten(1).size
  report['totalSessions'] = total_sessions

  report['allBrowsers'] = unique_browsers.map(&:upcase).sort.join(',')

  users_objects = users.map do |user|
    User.new(attributes: user, sessions: sessions_by_user[user[1]])
  end

  report['usersStats'] = {}
  collect_all_stats(report, users_objects)

  File.write('result.json', "#{report.to_json}\n")
end

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')
  end

  def test_result
    work
    expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
    assert_equal expected_result, File.read('result.json')
  end
end
