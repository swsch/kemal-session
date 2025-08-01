require "spec"
require "json"
require "../src/kemal-session"
require "file_utils"

SESSION_ID = Random::Secure.hex

def create_new_session
  create_context(Random::Secure.hex)
end

def create_context(session_id : String)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  # I would rather pass nil if no cookie should be created
  # but that throws an error
  unless session_id == ""
    Kemal::Session.config.engine.create_session(session_id)

    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new(Kemal::Session.config.cookie_name, Kemal::Session.encode(session_id))
    cookies.add_request_headers(headers)
  end

  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

def create_cookie_context(session_id : String, session)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  session.engine.create_session(session_id)
  cookies = HTTP::Cookies.new
  cookies << HTTP::Cookie.new(Kemal::Session.config.cookie_name, Kemal::Session.encode(session_id))
  cookies.add_request_headers(headers)
  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

macro expect_not_raises(file = __FILE__, line = __LINE__)
  %failed = false
  begin
    {{yield}}
  rescue %ex
    %ex_to_s = %ex.to_s
    backtrace = %ex.backtrace.map { |f| "  # #{f}" }.join "\n"
    fail "Expected no exception, got #<#{ %ex.class }: #{ %ex_to_s }> with backtrace:\n#{backtrace}", {{file}}, {{line}}
  end
end

class User
  include JSON::Serializable
  include Kemal::Session::StorableObject

  getter id, name

  def initialize(@id : Int32, @name : String)
  end
end

class UserTestSerialization
  def initialize(@id : Int64); end

  def self.from_json(parser)
    raise Exception.new("calling from_json")
  end

  def to_json(json)
    raise Exception.new("calling to_json")
  end

  include Kemal::Session::StorableObject
end

class UserTestDeserialization
  def initialize(@id : Int64); end

  def self.from_json(parser)
    raise Exception.new("calling from_json")
  end

  def to_json(json : JSON::Builder)
    json.number(@id)
  end

  include Kemal::Session::StorableObject
end

class First
  include JSON::Serializable
  include Kemal::Session::StorableObject

  def initialize(@id : Int64); end

  def name
    "first"
  end
end

class Second
  include JSON::Serializable
  include Kemal::Session::StorableObject

  def initialize(@id : Int64); end

  def name
    "second"
  end
end
