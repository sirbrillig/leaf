module Chingu::Traits::BoundingCircle
  def radius=(rad)
    @cached_radius = rad
  end
end

class Chingu::GameObjectMap
  attr_accessor :checked_squares
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

  def each_object_between(origin, dest)
    start_x = (origin.bb.x/ @grid[0]).to_i
    stop_x =  (dest.bb.x/ @grid[0]).to_i
    start_y = (origin.bb.y/ @grid[1]).to_i
    stop_y =  (dest.bb.y/ @grid[1]).to_i
    diff_x = (start_x - stop_x).abs
    diff_y = (start_y - stop_y).abs

    x = start_x
    y = start_y
    n = 1 + diff_x + diff_y
    x_inc = 1
    x_inc = -1 if start_x > stop_x
    y_inc = 1
    y_inc = -1 if start_y > stop_y
    error = diff_x - diff_y
    diff_x *= 2
    diff_y *= 2


    @checked_squares = []
    @checked_squares << [start_x,start_y]
    @checked_squares << [stop_x,stop_y]
    n.times do

      @checked_squares << [x,y]
      if @map[x] and @map[x][y] and @map[x][y] != origin and @map[x][y] != dest and @map[x][y].is_a? Leaf::BlocksVision
        yield @map[x][y] 
      end

      if error > 0
        x += x_inc
        error -= diff_y
      else
        y += y_inc
        error += diff_x
      end
    end
  end
end # GameObjectMap

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
