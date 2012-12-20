require 'rubygems'
require 'chingu'
require 'helpers'
require 'monkeypatch'
require 'game'
require 'movement'
require 'editor'
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
