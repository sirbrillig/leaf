module Leaf
  DEBUG = false

  module Hidable
    attr_accessor :hidden
    def update
      self.hide! if @hidden
      self.show! if not @hidden
      super
    end
  end

  module Standable
  end

  module Unpassable
  end

  module Climbable
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

class Chingu::GameObjectMap
  def collisions_with(game_object)
    start_x = (game_object.bb.left / @grid[0]).to_i
    stop_x =  (game_object.bb.right / @grid[0]).to_i

    objects = []
    (start_x ... stop_x).each do |x|
      start_y = (game_object.bb.top / @grid[1]).to_i
      stop_y =  (game_object.bb.bottom / @grid[1]).to_i

      (start_y ... stop_y).each do |y|
        objects << @map[x][y] if @map[x] && @map[x][y] && @map[x][y] != game_object  # Don't yield collisions with itself
      end
    end
    objects
  end
end

class Class
  def question_accessor(*args)
    args.each do |arg|
      self.class_eval("def #{arg}?;@#{arg};end")
      self.class_eval("def #{arg}=(val);@#{arg}=val;end")
    end
  end
end
