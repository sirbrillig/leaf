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

  class LevelEditor < Chingu::GameStates::Edit
    def setup
      super
      editable_game_objects.each { |object| object.show! if object.respond_to? :show! }
      on_input(:n, :toggle_snap_to_grid)
    end

    def toggle_snap_to_grid
      @snap_to_grid = !@snap_to_grid
    end

    def draw_toolbar_objects
      x = 20
      y = 60
      @classes.each do |klass|
        puts "Creating a #{klass}"  if @debug

        # We initialize x,y,zorder,rotation_center after creation
        # so they're not overwritten by the class initialize/setup or simular
        begin
          game_object = klass.create(:paused => true)
          game_object.x = x + 30
          game_object.y = y
          game_object.options[:toolbar] = true
          game_object.rotation_center = :center_center
          game_object.alpha = 255

          # Scale down object to fit our toolbar
          if game_object.image
            Text.create("#{klass.name.split('::').last.to_s[0..9]}\n#{game_object.width.to_i}x#{game_object.height.to_i}", :size => 18, :x=>x-16, :y=>y+28, :max_width => 100, :rotation_center => :top_left, :align => :center, :factor => 1)
            game_object.factor = 0.7
            x += 80
          else
            puts "Skipping #{klass} - no image" if @debug
            game_object.destroy
          end
        rescue
          puts "Couldn't use #{klass} in editor: #{$!}"
        end
      end        
    end
  end


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
