#!/usr/bin/env ruby

require "rack/websocket"
require "json"

# Ranchat module
module Ranchat

  # WebSocket class
  class Handler < Rack::WebSocket::Application
    @@connections = {}

    ## initialize
    # Init class
    # @param [String]  id  Chat ID
    ##

    def initialize(id)
      super({})

      @id = id
    end

    ## on_open
    # Handle client connect
    # @param [Array]  env  Environment
    ##

    def on_open(env)
      send_data([
        "system_message",
        { text: "Welcome to Ranchat" }
      ].to_json)

      # Add connection
      if @@connections.has_key?(@id)
        # Send user_connected event to all
        @@connections[@id].each do |c|
          c.send_data([
            "user_connect",
            { name: "Anonymous" }
          ].to_json)
      end
        @@connections[@id] << self
      else
        @@connections[@id] = [ self ]
      end



      p "<DEBUG> Client connected"
    end

    ## on_close
    # Handle client disconnect
    # @param [Array]  env  Environment
    ##

    def on_close(env)
      @@connections[@id].delete(self)

      p "<DEBUG> Client disconnected"
    end

    ## on_message
    # Handle client message
    # @param [Array]  env        Environment
    # @param [String] user_data  Client message
    ##

    def on_message(env, user_data)
      data       = JSON.parse(user_data)
      event_name = data[0]
      message    = data[1]

      # Send user_message event to all
      @@connections[@id].each do |c|
        c.send_data([
          "user_message",
          { from: message["from"], text: message["text"] }
        ].to_json)
      end

      p "<DEBUG> client message: " + user_data
    end

    ## on_error
    # Handle error
    # @param [Array]      env   Environment
    # @param [Exception]  mesg  Exception
    ##

    def on_error(env, error)
      p "<DEBUG> Client error: " + error.to_s, error.backtrace
    end
  end

  # Middleware class
  class Middleware

    ## initialize
    # Init class
    ##

    def initialize
      # Cache template
      file     = File.expand_path(File.dirname(__FILE__)) + "/html/index.html"
      @content = File.read(file)
      @length  = @content.size.to_s
    end

    ## call
    # Call middleware
    # @param [Array]  env  Environment
    ##

    def call(env)
      path = env["PATH_INFO"].to_s.squeeze("/")

      # Handle paths
      case(path)
        # Redirect to our form
        when "/"
          # Generate random string
          id = (0...10).map{65.+(rand(25)).chr}.join

          [ 302, { "Location" => "/#{id}" }, [] ]

        # Create websocket handler
        when /\/([A-Z]{10})\/ws/
          Ranchat::Handler.new($~[1]).call(env)

        # Send assets
        when /\/(.*)\.(js|css)/
          begin
            file    = File.expand_path(File.dirname(__FILE__)) + "/#{$~[2]}/#{$~[1]}.#{$~[2]}"
            content = File.read(file)
            length  = content.size.to_s

            [ 200, { "Content-Type" => "text/javascript",
              "Content-Length" => length }, [ content ] ]
          rescue => err
            [ 404, { "Content-Type" => "text/plain" }, [ "File not Found: #{path}" ] ]
          end

        # Send form
        when /\/([a-zA-Z]{10})/
          [ 200, { "Content-Type" => "text/html",
            "Content-Length" => @length }, [ @content ] ]

        # Bail out
        else
          [ 404, { "Content-Type" => "text/plain" }, [ "Broken?" ] ]
      end
    end
  end
end

# Rack
map "/" do
  run Ranchat::Middleware.new
end
