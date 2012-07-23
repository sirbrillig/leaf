module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => [0.3, 0.8], :debug => Leaf::DEBUG
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
      @animation.frame_names = {:face_right => 0, :face_left => 0, :climb => 0, :jump => 0}
      @image = @animation.first

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

    def speed=(spd)
      self.max_velocity_x = (spd)
    end

    def speed
      self.max_velocity_x
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
      self.velocity_y > 0.1
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

    # Return true if we're moving backwards or uncontrollably.
    def sliding?
      return true if @facing == :right and self.velocity_x < 0
      return true if @facing == :left and self.velocity_x > 0
      return true if @walking == false and @jumping == false and self.velocity_x != 0
      false
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

    def stop_totally
      @velocity_x = 0
      @acceleration_x = 0
      @walking = false
    end

    def stop_moving
      return unless walking?
      @acceleration_x = -@acceleration_x
      # Slow down (a little slower than we accel).
      @acceleration_x -= 0.15 if @acceleration_x > 0
      @acceleration_x += 0.15 if @acceleration_x < 0
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
      @velocity_y = 0
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


    # Return an array of objects we have collided with.
    def hit_objects
      game_state.game_object_map.collisions_with(self)
      #[game_state.game_object_map.from_game_object(self)]
    end

    # Return an object if we're standing over BackgroundObject.
    def on_background_object?
      @on_background_object
    end

    # Return the Platform we're standing on or nil.
    def standing_on_platform
      return nil if falling? or jumping?
      self.y += 1
      block = hit_objects.select {|o| o.is_a? Standable}.first
      self.y -= 1
      block
    end

    # Like standing_on_platform but to be used when falling.
    def hit_floor
      look_ahead = 10
      self.y += look_ahead
      block = hit_objects.select {|o| o.is_a? Standable}.first
      self.y -= look_ahead
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
    def fallen_off_platform?
      return false if jumping?
      under_foot = standing_on_platform
      return true unless under_foot
      future_distance = 10
      # Check left
      self.x -= future_distance
      under_foot_left = standing_on_platform
      self.x += future_distance
      # Check right
      self.x += future_distance
      under_foot_right = standing_on_platform
      self.x -= future_distance
      not (under_foot_left and under_foot_right)
    end

    # Return true if we walked off the left side of the screen.
    def hit_left_screen_edge?
      self.x < 0
    end

    # Return true if we walked off the right side of the screen.
    def hit_right_screen_edge?
      self.x > (game_state.viewport.x + $window.width)
    end

    # Return non-false if we walked into a wall (instance of Unpassable);
    # returns the first object we hit. 
    #
    # This will automatically be checked during normal movement and the method
    # #handle_hit_obstacle will be called, so you can handle the event there.
    def hit_obstacle?
      future_distance = 10
      # Check left
      self.x -= future_distance
      block_left = hit_objects.select {|o| o.is_a? Unpassable}.first
      self.x += future_distance
      return block_left if block_left
      # Check right
      self.x += future_distance
      block_right = hit_objects.select {|o| o.is_a? Unpassable}.first
      self.x -= future_distance
      return block_right if block_right
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


    def update
      # Make sure we stop after slowing down.
      stop_totally if @velocity_x != 0 and @velocity_x.between?(-0.2, 0.2)
      stop_totally if sliding?

      update_animation

      if floor = hit_floor
        self.y = floor.bb.top - 1
        land
      end

      @on_background_object = nil
      objects = self.hit_objects
      unless objects.empty?
        objects = [objects.first]
        puts "hit #{objects.collect{|o|o.class}.inspect}" if self.is_a? Player
        objects.each do |object|
          @on_background_object = object if object.is_a? BackgroundObject
          if rising? and object.is_a? Unpassable
            self.y = object.bb.bottom + self.image.height
            self.velocity = 0
          end
        end
      end

      if walking? and fallen_off_platform?
        handle_fell_off_platform
        self.x = previous_x if @prevent_falling
      end

      if block = hit_obstacle?
        self.x = previous_x
        #self.stop_totally # Unnecessary?
        handle_hit_obstacle(block) 
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

    end


    # Called when we run into a wall (Platform). 
    def handle_hit_obstacle(object)
    end

    # Called when we fall off screen.
    def handle_fell_off_screen
    end

    # Called when we're about to fall off a platform.
    def handle_fell_off_platform
    end

  end # Creature
end # Leaf

