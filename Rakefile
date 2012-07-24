task :default => :run

task :run do
  $LOAD_PATH.unshift 'lib'
#   $LOAD_PATH.unshift '~/.gem/ruby/1.8'
  require 'leaf'

  Leaf::Game.new.show
end

