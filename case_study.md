1. I used `sudo rbspy record ruby task-1.rb` + fasterer + rubocop performance + benchmark
2. rbspy showed that this is the 1st bottleneck:
````ruby
  file_lines.each do |line|
    cols = line.split(',')
    users = users + [parse_user(line)] if cols[0] == 'user'
    sessions = sessions + [parse_session(line)] if cols[0] == 'session'
  end
````
(many lines, for each line it does a split)
3. Inspecting the file showed that it consists of many rows like this:
````csv
user,0,Hazel,Margarete,19
session,0,0,Internet Explorer 50,81,2018-02-01
session,0,1,Safari 27,88,2017-10-28
...
````
4. I split the file_lines array into two arrays (users and sessions) using regex and used << instead of +=:
````ruby
users << line
````
instead of this
````ruby
users = users + [parse_user(line)]
````
5. Inefficient way to calculate unique browsers:
```
  sessions.each do |session|
    browser = session['browser']
    uniqueBrowsers += [browser] if uniqueBrowsers.all? { |b| b != browser }
  end
 ````
Resolved by doing map.uniq

6. The next bottleneck was `split`.
At that point I decided to use CSV library to parse the file (as it has a more optimized internal splitting mechanism)

7. I had a bunch of map statements.
I removed all the maps I could.

8. The next bottleneck was matching users to sessions.
I solved it using an adjacency list technique.

9. The stats calculator was inefficient and was used many times.
I converted it to one method that calculates all the stats in one go.

10. The program (with data_large) completes in under 30 secs in my PC now.
At this point rbspy says that the bottleneck is inside CSV parser.
I can't do anything about it.
So I stop here.
