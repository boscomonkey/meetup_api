#!/usr/bin/env ruby

require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),
                  "..", "lib", "meetup_api")

class MeetupApiTester < Test::Unit::TestCase
  
  def setup
    require File.join(File.expand_path(File.dirname(__FILE__)), 'api_key')

    @key = API_KEY
    @api = MeetupApi::Client.new(@key)
  end
  
  def test_instantiate_new_client
  end
  
  def test_fetch
    # 8337541 is ID for 'My Rake is Bigger than your Rake (Ooga Labs)'
    json = @api.fetch(MeetupApi::RSVPS_URI, :event_id => 8337541)
    assert_not_nil(json, 'json cannot be nil')
    assert_instance_of Hash, json
    assert_equal(2, json.keys.size, 'valid JSON should have only 2 keys')
    json
  end
  
  def test_fetch_meta
    json = test_fetch
    meta = json['meta']
    assert_not_nil(meta, "result metadata can't be nil")
  end
  
  def test_fetch_results
    json = test_fetch
    results = json['results']
    assert_not_nil(results, "result data can't be nil")
    assert_instance_of Array, results
    assert_equal(62, results.size, "should have 62 RSVP's")
  end
  
  def test_fetch_missing_2nd_argument
    json = @api.fetch(MeetupApi::RSVPS_URI)
    assert_not_nil(json)
  end
    
  def test_fetch_missing_event_id
    json = @api.fetch(MeetupApi::RSVPS_URI)
    assert_instance_of Hash, json
    assert_equal(2, json.keys.size, 'valid JSON should have only 2 keys')
    assert_not_nil(json['details'])
    assert_not_nil(json['problem'])
  end
  
  def test_fetch_unauthorized
    client = MeetupApi::Client.new('invalid_key')
    json = client.fetch(MeetupApi::RSVPS_URI, :event_id => 8337541)
    assert_instance_of Hash, json
    assert_equal(2, json.keys.size, 'valid JSON should have only 2 keys')
    assert_not_nil(json['details'])
    assert_not_nil(json['problem'])
  end

  
  def test_rsvp_valid
    ret = @api.get_rsvps :event_id => 8337541
    verify_my_rake_is_bigger_than_your_rake ret
  end
  
  def test_rsvp_missing_id
    begin
      ret = @api.get_rsvps({})
      flunk 'previous call should raise'
    rescue MeetupApi::ClientException => e
      assert_not_nil e.description
      assert_not_nil e.problem
    end
  end
  
  def test_events
    ret = @api.get_events :id => 8337541, :after => '01011970'
    assert_not_nil ret.meta
    assert_not_nil ret.results
    assert_instance_of Array, ret.results
    assert_equal 1, ret.results.size
    ret
  end
  
  def test_events_rsvps
    events = test_events
    rsvps = events.results.first.get_rsvps @api
    verify_my_rake_is_bigger_than_your_rake rsvps
  end
  
  private
  
  def verify_my_rake_is_bigger_than_your_rake(ret)
    assert_not_nil ret, "RSVP's for 'My Rake...' event should not be nil"
    assert_not_nil ret.meta
    assert_not_nil ret.results
    assert_instance_of Array, ret.results
    assert_equal 62, ret.results.size
    ret.results.each {|r| assert_instance_of MeetupApi::Rsvp, r}
  end

end
