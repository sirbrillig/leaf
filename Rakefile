task :default => :run

task :run do
  $LOAD_PATH.unshift 'lib'
  require 'leaf'

  Leaf::Game.new.show
end

