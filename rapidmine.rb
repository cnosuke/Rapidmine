require 'optparse'
require 'yaml'
require 'json'
require 'open-uri'
require 'pp'
require 'uri'
require 'net/https'

OPT = OptionParser.new
Version = "0.2 alpha"

class NotImplementationError < StandardError ;end

CONFIG = YAML.load(open("config.yaml").read)

class String
  def minify
    if self.size > 30
      return self[0..30] + "..."
    else
      self
    end
  end
end

class Rapidmine

  def http(method, url, data = nil)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    # https.ca_file = '/usr/share/ssl/cert.pem'
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    if data
      dd = { :issue => { } }
      data.each do |k,v|
        if k == :key
          dd[k.to_s] = v
        else
          dd[:issue][k] = v
        end
      end
    end

    https.start do
      if method == :post
        response = https.post( uri.path + "?" + uri.query, dd.to_json  , 'Content-Type' => "application/json" )
      else
        response = https.send( method, uri.path + "?" + uri.query )
      end
      return response.body
    end

  end

  def make_path(h)
    h[:key] = CONFIG["api"]
    m = h.delete(:model).to_s + ".json"
    path = CONFIG["url"] + m + "?"
    h.each{ |k,v|
      path << ( URI.encode(k.to_s) + "=" + URI.encode(v.to_s) + "&" )
    }
    path << "limit=100"
    return path
  end
  
  def get_model(model,opt = nil)
    h = { :model => model }
    if opt
      opt.each{ |k,v|
        h[k] = v
      }
    end
    j = JSON.parse(http(:get, make_path(h)))
    return j
  end

  def post_model(model,opt = nil, data = nil)
    h = { :model => model }
    data.merge!(opt)
    data[:key] = CONFIG["api"]
    j = JSON.parse(http(:post, make_path(h), data))
    return j
  end

  def create(model, opt)
    data = opt.delete(:data)
    j = post_model(model, opt, data)
    self.send("print_"+model.to_s, j)
  end

  def list(model, opt)
    j = get_model(model, opt)
    self.send("print_"+model.to_s, j)
  end

  def print_issues(j)
    if j['issues']
      j['issues'].each do |e|
        puts %( #{e['id']}\t#{e['subject']} -- [#{e['assigned_to']['name'] if e['assigned_to']}][#{e['status']['name']}][#{e['priority']['name']}] )
      end
    elsif j['issue']
      e = j['issue']
      puts %( #{e['id']}\t#{e['subject']} -- [#{e['assigned_to']['name'] if e['assigned_to']}][#{e['status']['name']}][#{e['priority']['name']}] )
    end
  end

  def create_issues(opt = nil)
    data = opt.delete(:data)
    j = post_model(:model, opt, data)
    pp j
  end

  def print_projects(j)
    j['projects'].each do |e|
      puts %( #{e['id']}\t#{e['name']} - #{e['description'].gsub(/\s/,'').minify } )
    end
  end

  def print_users(j)
    j['users'].each do |e|
      puts %( #{e['id']}\t#{e['firstname']} #{e['lastname']} <#{e['mail']}> )
    end
  end

  def change_user_to_id(user)
    unless user =~ /\d+/
      get_model(:users)['users'].each do |u|
        if u['mail'] =~ /#{user}/ || u['lastname'] =~ /#{user}/ || u['firstname'] =~ /#{user}/ then
          return u["id"] 
        end
      end
      return "nil"
    else
      user
    end
  end

  def change_project_to_id(pj)
    unless pj =~ /\d+/
      get_model(:projects)['projects'].each do |el|
        if ["identifier", "description", "name"].map{ |e| el[e] =~ /#{pj}/ }.inject(false){ |m,x| m || x } then
          return el["id"]
        end
      end
      return "nil"
    else
      pj
    end
  end
  
  def run(cmd)
    cmd[:assigned_to_id] = change_user_to_id(cmd[:assigned_to_id]) if cmd[:assigned_to_id]
    cmd[:project_id] = change_project_to_id(cmd[:project_id]) if cmd[:project_id]
    method = cmd.delete(:method).to_s
    model = cmd.delete(:model).to_s
    self.send(method, model, cmd)
  end

end

def print_help
  puts "ruby rapidmine.rb [OPT]"
  puts "-o, --open ISSUE_NUM : Open the issue on your default web browser"
  puts "-l, --list (projects|users|issues) : List out your(or someone's) issues(or projects|users)."
  puts "-c, --create (issues) : Create your(or someone's) issues. -s SUBJECT and -p PROJECT_NAME are needed."
  puts "[-u, --users USER_NAME | USER_ID]"
  puts "[-p, --project PROJECT_NAME | PROJECT_ID]"
  puts " * PROJECT_NAME and USER_NAME is compared by regular expression."
end

CMD = {
  :method => :list,
  :model => "issues",
  #:assigned_to_id => CONFIG["user"],
  :data => { }
}

OPT.on("-h","--help") do
  print_help
  exit
end

OPT.on("-l","--list [VAL]") do |e|
  CMD[:method] = :list
  if e
    CMD[:model] = e
  else
    CMD[:model] = "issues"
  end
end

OPT.on("-c","--create [VAL]") do |e|
  CMD[:method] = :create
  if e
    CMD[:model] = e
  else
    CMD[:model] = "issues"
  end
end

OPT.on("-u","--user VAL") do |e|
  CMD[:assigned_to_id] = e
end

OPT.on("-p","--project VAL") do |e|
  CMD[:project_id] = e
end

OPT.on("-s","--subject VAL") do |e|
  CMD[:data][:subject] = e
end

OPT.on("-S","--status VAL") do |e|
  CMD[:data][:status_id] = e
end

OPT.on("-P","--priority VAL") do |e|
  CMD[:data][:priority_id] = e
end

OPT.on("-T","--tracker VAL") do |e|
  CMD[:data][:tracker_id] = e
end

OPT.on("-o","--open VAL") do |e|
  system("open '#{CONFIG["url"]}/issues/#{e}'")
  exit
end

OPT.parse(ARGV)

mine = Rapidmine.new
mine.run(CMD)
