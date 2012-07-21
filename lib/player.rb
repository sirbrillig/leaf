module Leaf

  class Player < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/player2.png", :size => 50)
      @animation.frame_names = {:face_right => 0..1, :face_left => 2..3, :climb => 4..5, :jump => 5}
      @image = @animation.first

      @visible_area = VisibleArea.create(:x => self.x, :y => self.y)

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:holding_up, :holding_w], :up_pressed)
      on_input([:holding_down, :holding_s], :down_pressed)

      # FIXME: can movement be acceleration-based?
    end

    def up_pressed
      object = on_background_object?
      if object and object.respond_to? :climb_height
        climb_up(object)
      else
        jump
      end
    end

    def down_pressed
      object = on_background_object?
      if object and climbing?
        climb_down(object)
      end
    end

    def update
      super
      @visible_area.follow(self) if @visible_area
    end
  
    def handle_fell_off_screen
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
      self.hide! # Not sure if it's better to be visible.
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
      when 80..200
        return :middle
      when 0..79
        return :close
      else
        return :far
      end
    end

    def update
      # FIXME: it would be nice not to have to specify all classes here to be
      # illuminated. Could they have a mixin or trait?
      #
      # FIXME: line-of-sight should be blocked by solid objects (Platforms).
      self.each_collision(Guard, Walker, Watcher, Platform, BackgroundWall) do |area, object|
        range = self.range(object)
        case range
        when :far
          object.alpha = Leaf::Level::FAR_OBJECT_ALPHA
        when :middle
          object.alpha = Leaf::Level::MIDDLE_OBJECT_ALPHA
          object.noticed_player if object.respond_to? :noticed_player
        else
          object.alpha = Leaf::Level::CLOSE_OBJECT_ALPHA
          object.noticed_player if object.respond_to? :noticed_player
        end
        object.show!
      end
    end

  end # VisibleArea

end # Leaf

