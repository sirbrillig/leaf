module Leaf
  class Power < Creature
    attr_accessor :start_object
    def configure(image)
      self.image = Gosu::Image['media/'+image]
    end

    def activate
      raise "No activation has been written for this #{self.class} object."
    end

    def jump_forward
      # FIXME: fly forward! and down.
      self.acceleration_y = 0
      case start_object.facing
      when :left
        self.acceleration_x = -2
      when :right
        self.acceleration_x = 2
      end
    end
  end # Power

  class SmokeBomb < Power
    def setup
      configure('smokebomb.png')
    end

    def activate
      jump_forward
    end
  end
end
