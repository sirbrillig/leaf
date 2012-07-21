module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => [0.3, 0.8], :debug => Leaf::DEBUG
    traits :collision_detection, :timer, :velocity

    attr_accessor :on_background_object

    def setup
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
      @image = @animation.first

      @jumps = 0
      @speed = 4
      @walking = false
      @climbing = false
      @distance_climbed = 0
      @on_background_object = false

      self.zorder = Leaf::Level::SPRITES_LAYER
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

    def move_left
      @walking = true unless jumping?
      move(-(@speed), 0)
    end

    def move_right
      @walking = true unless jumping?
      move(@speed, 0)
    end

    def jump(distance=11)
      return if @jumps == 1
      return if @jump_delay
      return if falling?
      @image = @animation[1]
      @jumps += 1
      self.velocity_y = -(distance)
      @jump_delay = true
      after(700) { @jump_delay = false }
    end

    def land
      @image = @animation[0]
      @jumps = 0
    end

    def climbing?
      @climbing
    end

    def suspend_gravity
      return unless @acceleration_y > 0
      @previous_accel_y = @acceleration_y
      @acceleration_y = 0
    end

    def restore_gravity
      return unless @acceleration_y == 0
      @acceleration_y = @previous_accel_y
    end

    def climb_up(object)
      @image = @animation[1]
      @climbing = true
      suspend_gravity
      @distance_climbed += @speed
      # FIXME: the distance_climbed calculuation will be wrong if we start at
      # some other point of the tree.
      if @on_background_object.climb_height <= @distance_climbed
        @distance_climbed -= @speed
        #finish_climbing
        #jump(8)
      else
        move(0, -(@speed))
      end
    end
    
    def climb_down(object)
      @image = @animation[1]
      @climbing = true
      suspend_gravity
      @distance_climbed -= @speed
      move(0, @speed)
    end

    def finish_climbing
      restore_gravity
      @distance_climbed = 0
      @climbing = false
    end
    
    # Return the object we've hit if we collide with something.
    #
    # If you'd like to know about hitting floors or walls, see
    # #hit_something_below? and #hit_obstacle?
    def hit_something?
      game_state.game_object_map.from_game_object(self)
    end

    # Return the block we've hit if it's below us (see #hit_something?)
    def hit_something_below?
      block = hit_something?
      block and block.y >= self.y
    end

    def on_background_object?
      @on_background_object
    end

    # Return the Platform we're standing on or nil.
    def standing_on_platform
      return nil if falling? or jumping?
      self.y += 1
      block = hit_something?
      self.y -= 1
      return block if block
      nil
    end

    # Return true if we fell off the bottom of the screen. This will be
    # automatically checked during normal movement and the method
    # #handle_fell_off_screen will be called, so you can handle the event there.
    def fallen_off_bottom?
      self.y > $window.height
    end

    # Return true if we are about to fall off a Platform. Despite the name this
    # can be used to stop falling. This will be automatically checked during
    # normal movement and the method #handle_fell_off_platform will be called,
    # so you can handle the event there.
    def fallen_off_platform?(movement)
      return false if jumping?
      self.x += movement * 5
      test = standing_on_platform
      self.x -= movement * 5
      not test
    end

    # Return true if we walked off the left side of the screen.
    def hit_left_wall?
      self.x < 0
    end

    # Return true if we walked off the right side of the screen.
    def hit_right_wall?
      self.x > (game_state.viewport.x + $window.width)
    end

    # Return true if we walked into a wall (Platform). This will automatically
    # be checked during normal movement and the method #handle_hit_obstacle will
    # be called, so you can handle the event there.
    def hit_obstacle?(movement)
      test = false
      self.x += movement * 5
      if block = hit_something?
        test = true
      end
      self.x -= movement * 5
      test
    end

    # Called when we run into a wall (Platform). 
    def handle_hit_obstacle
    end

    # Called when we fall off screen.
    def handle_fell_off_screen
    end

    # Called when we're about to fall off a platform.
    def handle_fell_off_platform
    end

    def move(x, y)
      @image = @animation.next if @animation and walking?

      self.x += x
      self.x = previous_x if hit_something?
      if fallen_off_platform?(x) 
        handle_fell_off_platform
        self.x = previous_x if @prevent_falling
      end
      if hit_obstacle?(x)
        handle_hit_obstacle
      end
      @walking = false

      self.y += y
      if hit_something?
        land if jumping? and hit_something_below?
        self.y = previous_y
        self.velocity_y = 0
      end

      if climbing? 
        if @on_background_object
          finish_climbing if @distance_climbed <= 0
        else
          finish_climbing
        end
      end

      if game_state.viewport.outside?(self)
        if fallen_off_bottom?
          handle_fell_off_screen
        elsif hit_left_wall? or hit_right_wall?
          self.x = previous_x
        else
          self.y = previous_y
        end
      end
    end

  end # Creature
end # Leaf

