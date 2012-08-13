module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => [0.3, 0.8], :debug => Leaf::DEBUG
    traits :collision_detection, :timer, :velocity

    question_accessor :stopping, :jumping, :walking, :climbing, :hanging
    attr_accessor :climb_speed

    def setup
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
      @animation.frame_names = {
        :face_right => 0..1, 
        :face_left => 2..3, 
        :face_alert_right => 0..1, 
        :face_alert_left => 2..3, 
        :climb => 4..5, 
        :jump_left => 4..5, 
        :jump_right => 4..5, 
        :stopping_right => 0..1, 
        :stopping_left => 2..3,
        :hang_left => 4..5, 
        :hang_right => 4..5
      }
      @image = @animation.first

      @facing = :right

      self.zorder = Leaf::Level::SPRITES_LAYER
      self.acceleration_y = 0.5
      self.max_velocity_y = 20
      self.max_velocity_x = 4
      self.rotation_center = :bottom_center
      self.climb_speed = 1
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

    def falling?
      self.velocity_y > 0.1
    end

    def rising?
      self.velocity_y < 0
    end

    # Return true if we're moving backwards or uncontrollably.
    def sliding?
      return true if facing_right? and self.velocity_x < 0
      return true if facing_left? and self.velocity_x > 0
      return true if not walking? and not jumping? and not climbing? and self.velocity_x != 0
      false
    end


    def move_left
      @facing = :left
      return self.x -= self.climb_speed if climbing?
      @walking = true unless jumping?
      @stopping = false
      @acceleration_x = -0.3
    end

    def move_right
      @facing = :right
      return self.x += self.climb_speed if climbing?
      @walking = true unless jumping?
      @stopping = false
      @acceleration_x = 0.3
    end

    def stop_totally
      @velocity_x = 0
      @acceleration_x = 0
      @walking = false
      @stopping = false
    end

    def stop_moving
      return unless walking?
      return if stopping?
      @stopping = true
      @acceleration_x = -@acceleration_x
      # Slow down (a little slower than we accel).
      @acceleration_x -= 0.12 if @acceleration_x > 0
      @acceleration_x += 0.12 if @acceleration_x < 0
    end

    def jump(distance=11)
      return if jumping?
      return if @jump_delay
      return if falling?
      distance += 1 if walking? # FIXME: ideally this should be if walking for some time.
      self.velocity_y = -(distance)
      @jumping = true
      @jump_delay = true
      after(700) { @jump_delay = false }
    end

    def land
      @jumping = false
      @velocity_y = 0
      finish_climbing
    end

    def suspend_gravity
      return if @acceleration_y == 0
      @previous_accel_y = @acceleration_y
      @acceleration_y = 0
      @velocity_y = 0
    end

    def restore_gravity
      return unless @acceleration_y == 0
      @acceleration_y = @previous_accel_y
    end

    def hang(object)
      land if jumping?
      @climbing = true
      @hanging = true
      suspend_gravity
      stop_totally
    end

    def climb_up(object)
      self.y -= 10 unless climbing? # We've got to get off the ground
      land if jumping?
      @climbing = true
      suspend_gravity
      self.y -= 2
      stop_totally
    end
    
    def climb_down(object)
      land if jumping?
      @climbing = true
      suspend_gravity
      self.y += 2
      stop_totally
    end

    def finish_climbing
      restore_gravity
      @distance_climbed = 0
      @climbing = false
      @hanging = false
    end


    # Return an array of objects we have collided with.
    def hit_objects
      game_state.game_object_map.collisions_with(self)
      #[game_state.game_object_map.from_game_object(self)]
    end

    # Return an object if we're standing over BackgroundObject.
    def background_object
      game_state.background_object_map.collisions_with(self).first
    end

    #FIXME: deal with platforms that are at an angle, if possible.

    # Return the Platform we're standing on or nil.
    def standing_on_platform
      return nil if falling? or jumping?
      look_ahead = 10
      self.y += look_ahead
      block = hit_objects.select {|o| o.is_a? Standable}.first
      self.y -= look_ahead
      block
    end

    # Like standing_on_platform but to be used when falling.
    def hit_floor
      return nil if rising?
      look_ahead = 10
      self.y += look_ahead
      margin_of_error = 20
      block = hit_objects.select do |o| 
        o.is_a? Standable and o.bb.top.between?(self.bb.bottom - margin_of_error, self.bb.bottom + margin_of_error)
      end.last
      self.y -= look_ahead
      block
    end

    def hit_step
      return nil unless walking?
      return nil if jumping?
      look_ahead = 10
      if @facing == :right
        self.x += look_ahead
      else
        self.x -= look_ahead
      end
      margin_of_error = 25
      block = hit_objects.select do |o| 
        o.is_a? Standable and o.bb.top.between?(self.bb.bottom - margin_of_error, self.bb.bottom + margin_of_error)
      end.last
      if @facing == :right
        self.x -= look_ahead
      else
        self.x += look_ahead
      end
      block
    end

    def hit_hangable
      return nil unless self.is_a? Player
      return nil unless jumping? or hanging?
      look_ahead = 5
      self.y -= look_ahead
      margin_of_error = 10
      block = hit_objects.select do |o| 
        o.is_a? Hangable and o.bb.bottom.between?(self.bb.top - margin_of_error, self.bb.top + margin_of_error)
      end.last
      self.y += look_ahead
      block
    end

    def hit_ceiling
      return nil unless rising?
      block = hit_objects.select do |o|
        o.is_a? Unpassable
      end.last
    end

    # Return true if we fell off the bottom of the screen. This will be
    # automatically checked during normal movement and the method
    # #handle_fell_off_screen will be called, so you can handle the event there.
    def fallen_off_bottom?
      self.y > $window.height
    end

    # Return true if we are about to fall off a Platform. Despite the name this
    # can be used to stop falling. This will be automatically checked during
    # normal movement and the method in @prevent_falling will be called,
    # so you can handle the event there.
    def fallen_off_platform?
      return false if jumping?
      future_distance = 10
      block = nil
      if @velocity_x < 0
        # Check left
        self.x -= future_distance
        block = standing_on_platform
        self.x += future_distance
      elsif @velocity_x > 0
        # Check right
        self.x += future_distance
        block = standing_on_platform
        self.x -= future_distance
      end
      not block
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
      self.y -= 2 # Prevent hitting the floor.
      # Check left
      self.x -= future_distance
      block_left = hit_objects.select {|o| o.is_a? Unpassable}.first
      self.x += future_distance
      # Check right
      self.x += future_distance
      block_right = hit_objects.select {|o| o.is_a? Unpassable}.first
      self.x -= future_distance
      self.y += 2
      return block_left if block_left
      return block_right if block_right
    end

    # Return true if we support movement states and we're aware of something
    # amiss.
    def alert?
      return true if self.respond_to? :has_movement_state? and (has_movement_state?(:alert) or has_movement_state?(:noticed))
      false
    end


    def update_animation
      if stopping?
        @image = next_animation_frame(:stopping, @facing)
      elsif jumping?
        @image = next_animation_frame(:jump, @facing)
      elsif walking? and not climbing?
        if alert?
          @image = next_animation_frame(:face_alert, @facing)
        else
          @image = next_animation_frame(:face, @facing)
        end
      elsif hanging?
        if [self.x, self.y] != @previous_position
          @image = next_animation_frame(:hang, @facing)
        end
      elsif climbing?
        if [self.x, self.y] != @previous_position
          @image = next_animation_frame(:climb)
        end
      elsif @facing != @previous_facing
        if alert?
          @image = next_animation_frame(:face_alert, @facing)
        else
          @image = next_animation_frame(:face, @facing)
        end
      end
      @previous_facing = @facing
      @previous_position = [self.x, self.y]
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

      if floor = hit_step
        self.y = floor.bb.top - 1
        land
      end

      if floor = hit_floor
        # This will be called constantly while on the ground, which is fine.
        self.y = floor.bb.top - 1
        land
      end

      # FIXME: add a way to hang on to the edge of a platform as well as beneath
      if ceil = hit_hangable
        hang(ceil)
      elsif ceil = hit_ceiling
        self.y = ceil.bb.bottom + self.image.height
        self.velocity = 0
      end

      if walking? and fallen_off_platform?
        @prevent_falling.call if @prevent_falling
      end

      if block = hit_obstacle?
        self.x = previous_x
        handle_hit_obstacle(block) 
      end

      if hanging?
        finish_climbing unless hit_hangable
      else
        finish_climbing if climbing? and not background_object
      end

      update_animation

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

  end # Creature
end # Leaf

