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


  class Bomb < Power
    def setup
      configure('smokebomb.png')
      @max_explode_radius = 60
      @waver = true
    end

    def activate
      jump_forward
    end

    def explode
      @explosion_size = @max_explode_radius / 1.3
      @explode_out = true
      during(1.second) do
        if @explode_out 
          @explosion_size += 10 
          @explode_out = false if @explosion_size > @max_explode_radius
        else
          @explosion_size -= 10 
        end
      end
      self.then { self.destroy! }
    end

    def draw
      super
      if @explosion_size
        waver_size = 5
        @explosion_size_waver = @explosion_size + waver_size if @waver
        @explosion_size_waver = @explosion_size - waver_size unless @waver
        game_state.draw_circle(self.x, self.y, @explosion_size + 5 + waver_size, Gosu::Color::WHITE, Level::OVERLAY_LAYER, :additive)
        game_state.draw_circle(self.x, self.y, @explosion_size_waver, Gosu::Color::WHITE, Level::OVERLAY_LAYER, :additive)
        self.destroy! if @explosion_size < 1
      end
    end

    def hit_object(object)
      self.acceleration = self.velocity = 0
      explode
    end
  end

  class SmokeBomb < Bomb
    # FIXME: LOS should be blocked by smoke.
    def setup
      super
      @max_explode_radius = 150
    end

    def explode
      @explosion_size = 1
      during(2.seconds) do
        @explosion_size += 1
      end
      self.then do
        after(5.seconds) { self.destroy! }
      end
      every(0.2.seconds) { @waver = !@waver }
    end
  end
end
