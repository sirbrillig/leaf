require 'rubygems'
require 'chingu'

include Chingu
include Gosu

require 'game'
require 'creature'
require 'enemies'
require 'sprites'
require 'level'
require 'gameover'

if __FILE__ == $0
  Leaf::Game.new.show
end
