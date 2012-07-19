module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1#, :debug => true

    def setup
      @image = Gosu::Image["platform.png"]
      self.zorder = 10
      self.rotation_center = :top_right 
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
      on_input([:holding_up, :holding_w], :jump)

      @jumps = 0
      @speed = 4
      @walking = false

      self.zorder = 1000
      self.acceleration_y = 0.5
      self.max_velocity = 20
      self.rotation_center = :bottom_center
    end

    def jumping?
      @jumps > 0
    end

    def falling?
      self.velocity_y > 0.5
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
      # FIXME: add a jump timer so you can't jump more frequently than 0.2 sec.
      @image = @animation[1]
      @jumps += 1
      self.velocity_y = -11
    end

    def land
      @image = @animation[0]
      @jumps = 0
    end
    
    def hit_something?
      game_state.game_object_map.from_game_object(self)
    end

    def hit_something_below?
      block = hit_something?
      block and block.y >= self.y
    end

    def fallen_off_bottom?
      self.y > $window.height
    end

    def hit_left_wall?
      self.x < 0
    end

    def hit_right_wall?
      self.x > (game_state.viewport.x + $window.width)
    end

    def move(x, y)
      @image = @animation.next if @animation and walking?

      self.x += x
      self.x = previous_x if hit_something?
      @walking = false

      self.y += y
      if hit_something?
        land if jumping? and hit_something_below?
        self.y = previous_y
        self.velocity_y = 0
      end

      if game_state.viewport.outside?(self)
        if fallen_off_bottom?
          #$window.pop_game_state
          exit
        elsif hit_left_wall? or hit_right_wall?
          self.x = previous_x
        end
      end
    end

  end # Player

end # Leaf
