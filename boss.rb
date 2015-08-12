require 'sinatra'
require 'json'
require 'yaml'
require 'net/ssh'

post '/events' do
  logger.info 'Received webhook request from GitHub'
  deploy()
end

def deploy
  config = YAML.load File.read('config/boss.yml')
  Net::SSH.start(config['host'], 'boss', :keys => [config['key']]) do |ssh|
    body = request.body.read
    if body.length > 0
      data = JSON.parse body
      if data['ref'] == 'refs/heads/master' and !data['forced'] and data['commits'].length > 0
        output = ssh.exec! "cd #{config['path']} && git pull origin master && rake assets:precompile && unicornd upgrade"
        if output['Upgrade Complete'] then [200, 'Deploy completed.'] else [500, 'Deploy failed.'] end
      else
        [422, 'Payload isn\'t for master or doesn\'t contain any commits.']
      end
    else
      [400, 'Payload was empty.']
    end
  end
end
