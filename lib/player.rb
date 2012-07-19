module Leaf

  class Player < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/player.png", :size => 50)
      @image = @animation.first

      @visible_area = VisibleArea.create(:x => self.x, :y => self.y)

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:holding_up, :holding_w], :jump)
    end

    def update
      @visible_area.follow(self) if @visible_area
    end
  
    def fell_off_screen
      game_state.died
    end
  end # Player


  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1.1, :debug => Leaf::DEBUG
    def setup
      self.zorder = Leaf::Level::LIGHTED_LAYER
      self.rotation_center = :center
      @image = Gosu::Image["media/visiblearea.png"]
      self.alpha = 40
      self.radius = 250
    end

    def follow(sprite)
      self.x = sprite.x
      self.y = sprite.y
    end

    # Return the range area (:close, :middle, :far) of the object.
    def range(object)
      distance = game_state.distance(self, object)
      case distance
      when 100..200
        return :middle
      when 0..99
        return :close
      else
        return :far
      end
    end

    def update
      self.each_collision(Guard, Walker, Platform) do |area, object|
        range = self.range(object)
        case range
        when :far
          object.alpha = Leaf::Level::FAR_OBJECT_ALPHA
        when :middle
          object.alpha = Leaf::Level::MIDDLE_OBJECT_ALPHA
        else
          object.alpha = Leaf::Level::CLOSE_OBJECT_ALPHA
        end
        object.show!
      end
    end

  end # VisibleArea

end # Leaf

