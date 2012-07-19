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
end # Leaf
