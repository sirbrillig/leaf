module Leaf

  class Darkness < Chingu::GameObject
    def setup
      @image = nil
      self.zorder = Leaf::Level::OVERLAY_LAYER
      self.alpha = Leaf::Level::DARKNESS_ALPHA
    end

    def draw
      color = Gosu::Color::BLACK
      color.alpha = Leaf::Level::DARKNESS_ALPHA
      game_state.fill_rect(Chingu::Rect.new(x - 100, y - 100, 1224, 868), color, Leaf::Level::OVERLAY_LAYER)
    end
  end

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1#, :debug => true
    include Standable, Unpassable

    def setup
      @image = Gosu::Image["media/platform.png"]
      self.zorder = Leaf::Level::PLATFORM_LAYER
      self.rotation_center = :top_right 
      self.alpha = Leaf::Level::FAR_OBJECT_ALPHA
    end

  end # Platform

  class Background < Chingu::GameObject
    def setup
      @image = Gosu::Image["media/darkclouds.jpg"]
      self.zorder = Leaf::Level::BACKGROUND_LAYER
    end
  end # Background

  class BackgroundObject < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box

    def setup
      @image = Gosu::Image["media/blank.png"]
      self.zorder = Leaf::Level::BACKGROUND_OBJECT_LAYER
      self.rotation_center = :center
      self.alpha = Leaf::Level::FAR_OBJECT_ALPHA
    end

    def highlight(color)
      @highlighted = color
    end

    def draw
      super
      if @highlighted
        game_state.draw_rect(bb, Gosu::Color.new(@highlighted), Leaf::Level::LIGHTED_LAYER)
      end
    end
  end # BackgroundObject

  class Tree < BackgroundObject
    include Climbable
    trait :bounding_box, :scale => [0.6, 1], :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/tree.png"]
    end
  end # Tree

  class BackgroundWall < BackgroundObject
    include Climbable, BlocksVision
    trait :bounding_box, :scale => 1, :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/backgroundwall.png"]
      @climb_height = self.height - 30
    end
  end # BackgroundWall

  class BackgroundPlatform < BackgroundObject
    include Standable, BlocksVision
    trait :bounding_box, :scale => 1, :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/backgroundplatform.png"]
    end
  end # BackgroundPlatform

  class Lamp < VisibleArea
  end
end # Leaf
