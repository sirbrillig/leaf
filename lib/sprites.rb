module Leaf

  class Background < Chingu::GameObject
    def setup
      @image = Gosu::Image["media/background.jpg"]
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
    trait :bounding_box, :scale => 1, :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/backgroundwall.png"]
      @climb_height = self.height - 30
    end
  end # BackgroundWall

  class BackgroundPlatform < BackgroundObject
    include Standable, BlocksVision, Unpassable, Hangable
    trait :bounding_box, :scale => 1, :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/backgroundplatform.png"]
    end
  end # BackgroundPlatform

  class Lamp < VisibleArea
    def setup
      super
      @image = Gosu::Image["media/lamp.png"]
    end
  end
end # Leaf
