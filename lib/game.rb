module Leaf
  DEBUG = false

  module Standable
  end

  module Unpassable
  end

  module Climbable
    attr_accessor :climb_height
  end

	class Game < Chingu::Window
    def initialize
      super(1024, 768)
    end

    def setup
      push_game_state(Level2)
    end
	end # Game

end # Leaf

module Chingu::Traits::BoundingCircle
  def radius=(rad)
    @cached_radius = rad
  end
end

class Chingu::GameStates::Edit
  alias_method :old_setup, :setup
  def setup
    old_setup
    editable_game_objects.each { |object| object.show! if object.respond_to? :show! }
    on_input(:s, :toggle_snap_to_grid)
  end

  def toggle_snap_to_grid
    @snap_to_grid = !@snap_to_grid
  end
end
