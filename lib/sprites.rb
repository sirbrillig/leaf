module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box

    def setup
      @image = Gosu::Image["platform.png"]
      self.zorder = 10
    end

  end # Platform


  class Player < Chingu::GameObject
    trait :bounding_box
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "player.png", :size => 50)
      @image = @animation.first

      self.zorder = 1000
      self.acceleration_y = 0.5
      self.max_velocity = 20
      self.rotation_center = :bottom_center

      self.factor = 0.5
    end

    def move(x, y)
      self.factor_x = self.factor_x.abs   if x > 0
      self.factor_x = -self.factor_x.abs  if x < 0
      @image = @animation.next  if @animation

      self.x += x
      self.x = previous_x if game_state.game_object_map.from_game_object(self)

      self.y += y
      if block = game_state.game_object_map.from_game_object(self)
        if self.velocity_y < 0
          self.y = block.bb.bottom + self.height
        else
          self.y = block.bb.top + 1
        end
        self.velocity_y = 0
      end
    end
  end # Player

end # Leaf
