require 'rubygems'
require 'chingu'

include Chingu
include Gosu

require 'edit'
require 'game'
require 'creature'
require 'enemies'
require 'lights'
require 'sprites'
require 'player'
require 'level'
require 'gameover'

if __FILE__ == $0
  Leaf::Game.new.show
end
