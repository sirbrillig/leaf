module Leaf
  DEBUG = false

	class Game < Chingu::Window
    def initialize
      fullscreen = false
      super(1900, 900, fullscreen)
    end

    def setup
      push_game_state(Level2)
    end
	end # Game
end # Leaf

