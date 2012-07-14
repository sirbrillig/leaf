module Leaf

  class InGame
    include Rubygame::EventHandler::HasEventHandler

    def initialize(game)
      @game = game
      @screen = game.screen
      @queue = game.queue

    end
  end # InGame

end # Leaf
