module Leaf
  class Power < Chingu::GameObject
    traits :bounding_box, :collision_detection, :timer, :velocity
    attr_accessor :start_object
    def configure(image)
      self.image = Gosu::Image['media/'+image]
    end

    def activate
      raise "No activation has been written for this #{self.class} object."
    end

    def jump_forward
      self.x, self.y = start_object.x, start_object.y
      self.acceleration_y = 0.5
      self.max_velocity_y = 15
      self.y -= 20
      self.velocity_y = -4
      self.acceleration_x = 1.2
      self.max_velocity_x = 6
      self.acceleration_x = -self.acceleration_x if start_object.facing == :left
    end

    def update
      return if @collided
      if block = game_state.game_object_map.collisions_with(self).select { |o| o.is_a? Standable }.first
        self.hit_object(block)
        @collided = true
      end
    end

    def hit_object(object)
      self.destroy!
    end
  end # Power


  class SmokeBomb < Power
    def setup
      configure('smokebomb.png')
      @max_explode_radius = 60
    end

    def activate
      jump_forward
    end

    def explode
      @explosion = @max_explode_radius / 1.3
      @explode_out = true
      during(2.second) do
        if @explode_out 
          @explosion += 10 
          @explode_out = false if @explosion > @max_explode_radius
        else
          @explosion -= 10 
        end
      end
    end

    def draw
      super
      if @explosion
        game_state.draw_circle(self.x, self.y, @explosion, Gosu::Color::WHITE)
        self.destroy! if @explosion < 1
      end
    end

    def hit_object(object)
      self.acceleration = self.velocity = 0
      explode
    end
  end
end
