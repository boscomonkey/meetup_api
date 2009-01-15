require 'net/http'
require 'rubygems'
require 'json'

module MeetupApi
  DEV = ''
  API_BASE_URL = "http://api#{DEV}.meetup.com/"
  EVENTS_URI = 'events'
  RSVPS_URI = 'rsvps'
  
  class Client
    def initialize(apiKey)
      @key = apiKey
    end
    
    def get_events(args)
      ApiResponse.new(fetch(EVENTS_URI, args), Event)
    end

    def get_rsvps(args)
      ApiResponse.new(fetch(RSVPS_URI, args), Rsvp)
    end

    def fetch(uri, url_args={})
      url_args['format'] = 'json'
      url_args['key'] = @key if @key
      args = URI.escape(url_args.collect{|k,v| "#{k}=#{v}"}.join('&'))
      url = "#{API_BASE_URL}#{uri}/?#{args}"
      data = Net::HTTP.get_response(URI.parse(url)).body
      
      # ugh - rate limit error throws badly formed JSON
      begin
        JSON.parse(data)
      rescue Exception => e
        raise BaseException(e)
      end
    end
  end

  class ApiResponse
    attr_reader :meta, :results

    def initialize(json, klass)
      if (meta_data = json['meta'])
        @meta = meta_data
        @results = json['results'].collect {|hash| klass.new hash}
      else
        raise ClientException.new(json)
      end
    end
  end
  
  # Turns a hash into an object - see http://tinyurl.com/97dtjj
  class Hashit
    def initialize(hash)
      hash.each do |k,v|
        # create and initialize an instance variable for this key/value pair
        self.instance_variable_set("@#{k}", v)
        # create the getter that returns the instance variable
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})
        # create the setter that sets the instance variable (disabled for readonly)
        ##self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
      end
    end
  end
  
  # Base class for an item in a result set returned by the API.
  class ApiItem < Hashit
  end
  
  class Event < ApiItem
    def get_rsvps(apiclient, extraparams={})
      extraparams['event_id'] = self.id
      apiclient.get_rsvps extraparams
    end
    
    def to_s
      "Event #{self.id} named #{self.name} at #{self.time} (url: #{self.event_url})"
    end
  end
  
  class Rsvp < ApiItem
    def to_s
      "Rsvp by #{self.name} (#{self.link}) with comment: #{self.comment}"
    end
  end
  
  # Base class for unexpected errors returned by the Client
  class BaseException < Exception
    attr_reader :problem

    def initialize(e)
      @problem = e
    end
    
    def to_s
      "#{self.problem}"
    end
  end

  class ClientException < BaseException
    attr_reader :description
    
    def initialize(error_json)
      @description = error_json['details']
      @problem = error_json['problem']
    end
    
    def to_s
      "#{self.problem}: #{self.description}"
    end
  end

end
