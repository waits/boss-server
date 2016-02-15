require './boss.rb'
require 'minitest/autorun'
require 'rack/test'

class BossTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

#   def test_empty_body
#     post '/events'
#     assert_equal 400, last_response.status
#   end

  def test_push_nothing
    json = {:ref => 'refs/heads/master', :forced => false, :commits => [], :repository => {:name => 'web'}}.to_json
    post '/events', json
    assert_equal 422, last_response.status
  end

  def test_push_branch
    json = {:ref => 'refs/heads/not-master', :forced => false, :commits => [{:id => '123'}], :repository => {:name => 'web'}}.to_json
    post '/events', json
    assert_equal 422, last_response.status
  end

  def test_force_master
    json = {:ref => 'refs/heads/master', :forced => true, :commits => [{:id => '456'}], :repository => {:name => 'web'}}.to_json
    post '/events', json
    assert_equal 422, last_response.status
  end

  def test_push_master
    json = {:ref => 'refs/heads/master', :forced => false, :commits => [{:id => '789'}], :repository => {:name => 'web'}}.to_json
    post '/events', json
    assert_equal 200, last_response.status
  end
end
