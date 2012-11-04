require 'rubygems'
# require '~/.gem/ruby/1.8/gems/chingu-0.9rc8/lib/chingu'
require 'chingu'

include Chingu
include Gosu

#require 'edit'
require 'helpers'
require 'monkeypatch'
require 'game'
require 'movement'
require 'editor'
require 'gfx'
require 'creature'
require 'enemies'
require 'lights'
require 'sprites'
require 'player'
require 'level'
require 'gameover'
require 'youwin'
require 'powers'

if __FILE__ == $0
  Leaf::Game.new.show
end
