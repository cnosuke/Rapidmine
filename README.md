Rapidmine
=========

超速でredmine使えるようにしたいプロジェクト。

##名前について
RedmineのAPIでRapidにするのでR**api**dmine

##使い方
### config.yaml を作って下さい。
中身は下のような感じで。
<pre>
url: https://your.redmine.path/
api: your_api_key (cf. redmine's API key)
user: yourEmail@example.com
</pre>

### チケットの一覧を見る
<pre>
ruby rapidmine.rb --list issues --user cnosuke --project testProject
</pre>

もしくは下記でもOK
<pre>
ruby rapidmine.rb -l -u cnosuke -p testProject
</pre>

オプションなどは下記ヘルプにて。
<pre>
ruby rapidmine.rb -h
</pre>

### チケットを作る
<pre>
ruby rapidmine.rb --create issues --project testProject --user lovelykitty -s 'Drink a cup of water'
</pre>

もしくは下記でもOK
<pre>
ruby rapidmine.rb -c -p test -u lovelykitty -s 'Drink a cup of water'
</pre>

### オプションとか
下記ヘルプに適当に書いてあります。雑過ぎるかも。
<pre>
ruby rapidmine.rb -h
</pre>

### チケットの中を見たい！
<pre>
ruby rapidmine.rb -o 1234
</pre>
のようにしたらブラウザで1234番のチケットが見れるはずなのでそれで勘弁して.

