require 'mongrel_cluster/recipes'

set :application, "listlibrary.net"

set :scm, :git
set :repository, "harkins@argyle.redirectme.net:~/biz/listlibrary"
set :repository, "git@github.com:Harkins/listlibrary.git"

set :deploy_to, "/home/listlibrary/listlibrary.net"
set :deploy_via, :copy
set :branch, "master"
set :git_enable_submodules, 1

set :user, "listlibrary"
set :domain, "tron.dreamhost.com"
set :use_sudo, false
set :ssh_options, { :forward_agent => true }
set :spinner_user, nil

role :web, "listlibrary.net"
role :app, "listlibrary.net"
role :db, "listlibrary.net"

namespace :deploy do
  desc "Restarting Passenger with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "Task '#{t}' is unneeded with Passenger"
    task t, :roles => :app do ; end
  end

  desc "Clean up old page caches, which can grow quite large"
  task :clean_up_cache, :roles => :web do
    run "rm -rf #{previous_release}/public/page_cache"
  end

  after "deploy:restart", "deploy:clean_up_cache"
end
