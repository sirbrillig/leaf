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

  def each_object_between(origin, destination)
    # FIXME: this is not a good line-of-sight calculation. do better!
    start_x = (origin.bb.centerx / @grid[0]).to_i
    stop_x =  (destination.bb.centerx / @grid[0]).to_i
    start_y = (origin.bb.centery / @grid[1]).to_i
    stop_y =  (destination.bb.centery / @grid[1]).to_i

    distance_x = (start_x - stop_x).abs
    distance_y = (start_y - stop_y).abs

    if distance_y == 0
      puts "y = 0"
      (start_x .. stop_x).each do |x|
        yield @map[x][start_y] if @map[x] and @map[x][start_y]
      end
    elsif distance_x == 0
      puts "x = 0"
      (start_y .. stop_y).each do |y|
        yield @map[start_x][y] if @map[start_x] and @map[start_x][y]
      end
    elsif distance_y == distance_x
      puts "x == y"
      (start_x .. stop_x).each do |x|
        yield @map[x][start_y + x] if @map[x] and @map[x][start_y + x]
      end
    elsif distance_y > distance_x
      puts "y (#{distance_y}) > x (#{distance_x})"
      next_line = (distance_y / distance_x).round
      y = start_y
      (start_x .. stop_x).each do |x|
        y += 1 if (x % next_line) == 0
        yield @map[x][y] if @map[x] and @map[x][y]
      end
    elsif distance_x > distance_y
      puts "x (#{distance_x}) > y (#{distance_y})"
      next_line = (distance_x / distance_y).round
      y = start_y
      (start_x .. stop_x).each do |x|
        y += 1 if (x % next_line) == 0
        yield @map[x][y] if @map[x] and @map[x][y]
      end
    end
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

class Numeric
  def seconds
    self * 1000
  end
  alias_method :second, :seconds

  def minutes
    self * 1000 * 1000
  end
  alias_method :minute, :minutes
end
