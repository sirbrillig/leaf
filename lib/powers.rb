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
      self.x, self.y = start_object.x, start_object.y-15
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

  
  class Explosion < Chingu::GameObject
    trait :bounding_box
    traits :collision_detection, :timer
    def setup
      self.rotation_center = :bottom_center
      @animation = Animation.new(:file => "media/explosion.png", :width => 128, :height => 128, :loop => false)
      @animation.delay = 200
      @animation.on_frame(15) { self.destroy! }
      self.image = @animation.first
      #FIXME: the explosion should alert guards
    end

    def update
      self.image = @animation.next
    end
  end # Explosion


  class Bomb < Power
    def setup
      configure('smokebomb.png')
      @max_explode_radius = 60
      @explosion = nil
    end

    def activate
      jump_forward
    end

    def explode
      @explosion = Explosion.create(:x => self.x, :y => self.y)
      @explosion.explosion_size = @max_explode_radius / 1.3
      @explode_out = true
      during(1.second) do
        if @explode_out 
          @explosion.explosion_size += 10 
          @explode_out = false if @explosion.explosion_size > @max_explode_radius
        else
          @explosion.explosion_size -= 10 
        end
      end
      self.then { @explosion.destroy! if @explosion; self.destroy! }
    end

    def draw
      super
      @explosion.draw if @explosion
    end

    def hit_object(object)
      self.acceleration = self.velocity = 0
      explode
    end
  end # Bomb

  class SmokeBomb < Bomb
    def setup
      super
    end

    def explode
      @explosion = Explosion.create(:x => self.x, :y => self.y)
      self.destroy!
    end
  end
end
