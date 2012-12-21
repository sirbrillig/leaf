module Chingu::Traits::BoundingCircle
  def radius=(rad)
    @cached_radius = rad
  end
end

class Chingu::GameObjectMap
  #
  # Yields to the block each GameObject in this map's grid which lies between
  # two GameObjects: origin and dest. 
  #
  def each_object_between(origin, dest)
    grid_spaces_between(origin, dest) do |x, y|
      obj = game_object_at(x, y)
      yield if obj and obj != origin and obj != dest
    end
  end

  #
  # Options can contain the keys :target and :only.
  #
  # Returns true if GameObject options[:target] is between GameObjects origin and dest.
  #
  # If the target is nil, returns true if any GameObject in this map's grid lies
  # between origin and dest.
  #
  # If options[:only] is set, return true only if the matched object is_a?
  # options[:only].
  #
  def object_between?(origin, dest, options={})
    grid_spaces_between(origin, dest) do |x, y|
      if options[:target]
        x_pixels = x * @grid[0]
        y_pixels = y * @grid[1]
        return true if options[:target].collision_at?(x_pixels, y_pixels) 
      else
        obj = game_object_at(x, y)
        if options[:only]
          return true if obj and obj != origin and obj != dest and obj.is_a? options[:only]
        else
          return true if obj and obj != origin and obj != dest
        end
      end
    end
    return false
  end

  #
  # Return the GameObject at the grid coordinates (not pixel coordinates) x and
  # y. If there is no object there, return nil.
  #
  def game_object_at(x, y)
      return @map[x][y] if @map[x] and @map[x][y]
      return nil
  end

  #
  # Returns an array of [x, y] grid coordinate pairs in this map's grid between
  # the GameObjects origin and dest. 
  #
  # If a block is given, the method will yield x, y to the block for each grid
  # square.
  #
  def grid_spaces_between(origin, dest)
    # Note: x and y here are a Grid location, not pixel coordinates.
    raise "Expected GameObject as origin, got #{origin.class}" unless origin.is_a? Chingu::GameObject
    raise "Expected GameObject as dest, got #{dest.class}" unless dest.is_a? Chingu::GameObject
    start_x = (origin.bb.x/ @grid[0]).to_i
    stop_x =  (dest.bb.x/ @grid[0]).to_i
    start_y = (origin.bb.y/ @grid[1]).to_i
    stop_y =  (dest.bb.y/ @grid[1]).to_i
    diff_x = (start_x - stop_x).abs
    diff_y = (start_y - stop_y).abs

    x = start_x
    y = start_y
    n = 1 + diff_x + diff_y
    x_inc = 1 #FIXME: do fewer checks
    x_inc = -1 if start_x > stop_x
    y_inc = 1
    y_inc = -1 if start_y > stop_y
    error = diff_x - diff_y
    diff_x *= 2
    diff_y *= 2


    checked_squares = []
    checked_squares << [start_x,start_y]
    checked_squares << [stop_x,stop_y]
    n.times do

      checked_squares << [x,y]
      yield(x, y) if block_given?

      if error > 0
        x += x_inc
        error -= diff_y
      else
        y += y_inc
        error += diff_x
      end

    end

    return checked_squares
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

