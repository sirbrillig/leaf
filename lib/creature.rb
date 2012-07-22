module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => [0.3, 0.8], :debug => Leaf::DEBUG
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
      @animation.frame_names = {:face_right => 0, :face_left => 0, :climb => 0, :jump => 0}
      @image = @animation.first

      @speed = 4
      @jumping = false
      @walking = false
      @climbing = false
      @distance_climbed = 0
      @on_background_object = false
      @facing = :right

      self.zorder = Leaf::Level::SPRITES_LAYER
      self.acceleration_y = 0.5
      self.max_velocity_y = 20
      self.max_velocity_x = 4
      self.rotation_center = :bottom_center
    end

    def facing_right?
      @facing == :right
    end

    def facing_left?
      @facing == :left
    end

    def jumping?
      @jumping
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

    def climbing?
      @climbing
    end


    def move_left
      @walking = true unless jumping?
      @facing = :left
      @acceleration_x = -0.3
    end

    def move_right
      @walking = true unless jumping?
      @facing = :right
      @acceleration_x = 0.3
    end

    def stop_moving
      @acceleration_x = -@acceleration_x
      # Slow down a little slower.
      @acceleration_x -= 0.1 if @acceleration_x > 0
      @acceleration_x += 0.1 if @acceleration_x < 0
    end

    def jump(distance=11)
      return if jumping?
      return if @jump_delay
      return if falling?
      self.velocity_y = -(distance)
      @jumping = true
      @jump_delay = true
      after(700) { @jump_delay = false }
    end

    def land
      @jumping = false
    end

    def suspend_gravity
      return unless @acceleration_y > 0
      @previous_accel_y = @acceleration_y
      @acceleration_y = 0
      @velocity_y = 0
    end

    def restore_gravity
      return unless @acceleration_y == 0
      @acceleration_y = @previous_accel_y
    end

    def climb_up(object)
      @climbing = true
      suspend_gravity
      @distance_climbed += @speed
      # FIXME: the distance_climbed calculuation will be wrong if we start at
      # some other point of the tree.
      if @on_background_object.climb_height <= @distance_climbed
        @distance_climbed -= @speed

        # Jump off the top of the object. 
        finish_climbing
        jump(8)
      else
        move(0, -(@speed))
      end
    end
    
    def climb_down(object)
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
      block = game_state.game_object_map.from_game_object(self)
      return block if block
      block = on_background_object?
      return block if block and block.kind_of? Standable
      false
    end

    # Return the block we've hit if it's below us (see #hit_something?)
    def hit_something_below?
      block = hit_something?
      return block if block and block.y >= self.y
      false
    end

    # Return an object if we're standing over BackgroundObject.
    def on_background_object?
      @on_background_object
    end

    # Return the Platform we're standing on or nil.
    def standing_on_platform
      return nil if falling? or jumping?
      self.y += 1
      block = hit_something?
      self.y -= 1
      block
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
    def hit_left_screen_edge?
      self.x < 0
    end

    # Return true if we walked off the right side of the screen.
    def hit_right_screen_edge?
      self.x > (game_state.viewport.x + $window.width)
    end

    # Return non-false if we walked into a wall (Platform); returns the object
    # we hit. This will automatically be checked during normal movement and the
    # method #handle_hit_obstacle will be called, so you can handle the event
    # there.
    def hit_obstacle?(movement)
      test = false
      self.x += movement * 5
      if block = hit_something?
        test = block
        block2 = hit_something_below?
        test = false if block == block2
      end
      self.x -= movement * 5
      test
    end


    def update_animation
      if walking?
        @image = next_animation_frame(:face, @facing)
      elsif jumping?
        @image = next_animation_frame(:face, @facing)
      elsif climbing?
        @image = next_animation_frame(:climb)
      end
    end

    def next_animation_frame(tag, facing=nil)
      tag = "#{tag}_#{facing}".to_sym if facing
      return @animation.next unless @animation[tag]
      return @animation[tag] if @animation[tag].is_a? Gosu::Image
      return @animation[tag].next
    end

    def move(x, y)
      self.x += x
      self.each_collision(Platform) do |me, object|
        self.x = previous_x
        break
      end

      if fallen_off_platform?(x) 
        handle_fell_off_platform
        self.x = previous_x if @prevent_falling
      end

      handle_hit_obstacle if hit_obstacle?(x)

      self.y += y
    end

    def update
      # Make sure we stop.
      if @velocity_x.between?(-0.1, 0.1)
        @velocity_x = 0
        @acceleration_x = 0
        @walking = false
      end

      update_animation

      self.each_collision(Platform) do |me, object|
        if rising?
          self.y = object.bb.bottom + self.image.height
          self.velocity = 0
        else
          land
          self.y = object.bb.top - 1
        end
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
        elsif hit_left_screen_edge? or hit_right_screen_edge?
          self.x = previous_x
        else
          self.y = previous_y
        end
      end

      @on_background_object = nil
      # FIXME: any way we can avoid listing all BackgroundObjects here?
      self.each_collision(Tree, BackgroundWall, BackgroundPlatform) { |creature, object| @on_background_object = object if object.is_a? BackgroundObject }
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

  end # Creature
end # Leaf

