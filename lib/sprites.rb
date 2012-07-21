module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1#, :debug => true

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
  end # BackgroundObject

  class Tree < BackgroundObject
    include Climbable
    trait :bounding_box, :scale => [0.5, 1], :debug => Leaf::DEBUG
    def setup
      super
      @image = Gosu::Image["media/tree.png"]
      @climb_height = self.height - 30
    end
  end # Tree
end # Leaf
