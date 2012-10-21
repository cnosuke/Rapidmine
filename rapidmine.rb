require 'optparse'
require 'yaml'
require 'json'
require 'open-uri'
require 'pp'

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
  def make_path(h)
    h[:key] = CONFIG["api"]
    m = h.delete(:model).to_s + ".json"
    path = CONFIG["url"] + m + "?"
    h.each{ |k,v|
      path << ( k.to_s + "=" + v.to_s + "&" )
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
    j = JSON.parse(open(make_path(h)).read)
    return j
  end

  def list_issues(opt = nil)
    j = get_model(:issues, opt)
    j['issues'].each do |e|
      puts %( #{e['id']}\t#{e['subject']} - [#{e['status']['name']}][#{e['priority']['name']}] )
    end
  end

  def list_projects(opt = nil)
    j = get_model(:projects, opt)
    j['projects'].each do |e|
      puts %( #{e['id']}\t#{e['name']} - #{e['description'].gsub(/\s/,'').minify } )
    end
  end

  def list_users(opt = nil)
    j = get_model(:users, opt)
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
    m = cmd.delete(:method)
    self.send(m, cmd)
  end

end

def print_help
  puts "ruby rapidmine.rb [OPT]"
  puts "-l, --list (projects|users|issues)"
  puts "-u, --users USER_NAME | USER_ID"
  puts "-p, --project PROJECT_NAME | PROJECT_ID"
  puts " * PROJECT_NAME and USER_NAME is compared by regular expression."
end

mine = Rapidmine.new
CMD = {}

OPT.on("-h","--help") do
  print_help
  exit
end

OPT.on("-l","--list VAL") do |e|
  CMD[:method] = "list_"+e
end

OPT.on("-u","--user VAL") do |e|
  CMD[:assigned_to_id] = e
end

OPT.on("-p","--project VAL") do |e|
  CMD[:project_id] = e
end

OPT.parse(ARGV)

if ARGV.size == 0 then
  print_help
else
  mine.run(CMD)
end
