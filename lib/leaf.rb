require 'rubygems'
require 'chingu'

include Chingu
include Gosu

require 'game'
require 'creature'
require 'sprites'
require 'level'

if __FILE__ == $0
  Leaf::Game.new.show
end
