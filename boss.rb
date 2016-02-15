require 'sinatra'
require 'json'
require 'yaml'
require 'net/ssh'

post '/events' do
  logger.info 'Received webhook request from GitHub'
  deploy()
end

def deploy
  body = request.body.read
#   return [400, 'Payload was empty.'] unless body.size > 0
  data = JSON.parse(body)
  repos = YAML.load(File.read('config/repos.yml'))
  config = repos[data['repository']['name']]
  Net::SSH.start(config['host'], config['user'], :keys => [config['key']]) do |ssh|
    if data['ref'] == 'refs/heads/master' and !data['forced'] and data['commits'].length > 0
      output = ssh.exec! "cd #{config['path']} && git pull origin master && bin/rake assets:precompile && unicornd upgrade"
      puts output
      if output['Upgrade Complete'] then [200, 'Deploy completed.'] else [500, 'Deploy failed.'] end
    else
      [422, 'Payload isn\'t for master or doesn\'t contain any commits.']
    end
  end
end
