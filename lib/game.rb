module Leaf
  DEBUG = true

	class Game < Chingu::Window
    def initialize
      fullscreen = false
      super(1024, 768, fullscreen)
    end

    def setup
      push_game_state(Level2)
    end
	end # Game
end # Leaf

