module Leaf
  DEBUG = false

	class Game < Chingu::Window
    def initialize
      super(1024, 768)
    end

    def setup
      push_game_state(Level1)
    end
	end # Game
end # Leaf

module Chingu::Traits::BoundingCircle
  def radius=(rad)
    @cached_radius = rad
  end
end
