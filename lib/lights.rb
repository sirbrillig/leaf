module Leaf

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
      self.each_collision(Guard, Walker, Watcher, Platform, BackgroundWall, BackgroundPlatform) do |area, object|
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

  class DetectionArea < VisibleArea
    def setup
      super
      self.hide! # Not sure if it's better to be visible.
    end

    def update
      # FIXME: it would be nice not to have to specify all classes here to be
      # illuminated. Could they have a mixin or trait?
      #
      # FIXME: line-of-sight should be blocked by solid objects (Platforms).
      self.each_collision(Guard, Walker, Watcher, Platform, BackgroundWall, BackgroundPlatform) do |area, object|
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
  end # DetectionArea


end # Leaf
