module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1#, :debug => true

    def setup
      @image = Gosu::Image["platform.png"]
      self.zorder = 10
      self.rotation_center = :top_right # FIXME: where the heck would be a good spot?
    end

  end # Platform


  class Player < Chingu::GameObject
    trait :bounding_box, :scale => 0.8#, :debug => true
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "player.png", :size => 50)
      @image = @animation.first

      on_input([:holding_left, :holding_a], :holding_left)
      on_input([:holding_right, :holding_d], :holding_right)
      on_input([:up, :w], :jump)

      @jumps = 0
      @speed = 4
      @walking = false

      self.zorder = 1000
      self.acceleration_y = 0.5
      self.max_velocity = 20
      self.rotation_center = :bottom_center

      #self.factor = 0.5
    end

    def jumping?
      @jumps > 0
    end

    def falling?
      self.velocity_y > 0
    end

    def rising?
      self.velocity_y < 0
    end

    def walking?
      @walking
    end

    def holding_left
      @walking = true unless jumping?
      move(-(@speed), 0)
    end

    def holding_right
      @walking = true unless jumping?
      move(@speed, 0)
    end

    def jump
      return if @jumps == 1
      @jumps += 1
      self.velocity_y = -11
    end

    def land
      @jumps = 0
    end
    
    def hit_something?
      game_state.game_object_map.from_game_object(self)
    end

    def move(x, y)
      @image = @animation.next if @animation and walking?

      self.x += x
      if block = hit_something?
        self.x = previous_x
      end
      @walking = false

      self.y += y
      if hit_something?
        self.y = previous_y
        land if falling?
        self.velocity_y = 0
      end
    end

  end # Player

end # Leaf
