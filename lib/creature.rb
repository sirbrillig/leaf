module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => 0.8#, :debug => true
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "media/enemy.png", :size => 50)
      @image = @animation.first

      @jumps = 0
      @speed = 4
      @walking = false

      self.zorder = Leaf::Level::SPRITES_LAYER
      self.acceleration_y = 0.5
      self.max_velocity = 20
      #self.rotation_center = :bottom_center
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

    def move_left
      @walking = true unless jumping?
      move(-(@speed), 0)
    end

    def move_right
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

    def fell_off_screen
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
          fell_off_screen
        elsif hit_left_wall? or hit_right_wall?
          self.x = previous_x
        else
          self.y = previous_y
        end
      end
    end

  end # Creature
end # Leaf

