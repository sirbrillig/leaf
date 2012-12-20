module Leaf
  class Creature < Chingu::GameObject
    trait :bounding_box, :scale => [0.4, 1], :debug => Leaf::DEBUG
    traits :collision_detection, :timer, :velocity

    question_accessor :stopping, :jumping, :walking, :climbing, :hanging, :edging, :running
    attr_accessor :climb_speed, :facing, :running_jump_velocity, :running_time, :walk_accel

    def setup
      @animation = Chingu::Animation.new(:file => "media/blank.png", :size => 50)
      @image = @animation.first

      @facing = :right

      self.zorder = Leaf::Level::SPRITES_LAYER
      self.factor_x = 1
      self.acceleration_y = 0.5
      self.max_velocity_y = 20
      self.max_velocity_x = 4
      self.rotation_center = :bottom_center
      self.climb_speed = 1.2
      self.walk_accel = 0.4
      self.running_jump_velocity = 13
      self.running_time = 0.4
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

    def standing?
      not (jumping? or hanging? or climbing? or edging?)
    end

    # Return true if we're moving backwards or uncontrollably.
    def sliding?
      return true if facing_right? and self.velocity_x < 0
      return true if facing_left? and self.velocity_x > 0
      return true if not walking? and not jumping? and not climbing? and self.velocity_x != 0
      false
    end


    def move_left
      return land if edging? and facing_right?
      return if edging?
      @facing = :left
      return self.x -= self.climb_speed if climbing?
      @walking = true unless jumping?
      after(self.running_time.seconds) { self.running = true if walking? and not stopping? and @facing == :left }
      @stopping = false
      @acceleration_x = -self.walk_accel
    end

    def move_right
      return land if edging? and facing_left?
      return if edging?
      @facing = :right
      return self.x += self.climb_speed if climbing?
      @walking = true unless jumping?
      after(self.running_time.seconds) { self.running = true if walking? and not stopping? and @facing == :right }
      @stopping = false
      @acceleration_x = self.walk_accel
    end

    def stop_totally
      @velocity_x = 0
      @acceleration_x = 0
      @walking = false
      @stopping = false
      self.running = false
    end

    def stop_moving
      return unless walking?
      return if stopping?
      self.running = false
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
      distance = self.running_jump_velocity if running?
      self.velocity_y = -(distance)
      @jumping = true
      @jump_delay = true
      after(700) { @jump_delay = false }
    end

    def land
      @jumping = false
      @hanging = false
      @edging = false
      @climbing = false
      @velocity_y = 0
      restore_gravity
    end

    def suspend_gravity
      return if @acceleration_y == 0
      @previous_accel_y = @acceleration_y
      @acceleration_y = 0
      @velocity_y = 0
    end

    def restore_gravity
      return unless @acceleration_y == 0 and @previous_accel_y > 0
      @acceleration_y = @previous_accel_y
      @previous_accel_y = 0
    end

    def edge_hang
      hang
      @edging = true
    end

    def hang
      land if jumping?
      @climbing = true
      @hanging = true
      suspend_gravity
      stop_totally
    end

    def climb_up
      self.y -= 10 unless climbing? # We've got to get off the ground
      land if jumping?
      @climbing = true
      suspend_gravity
      self.y -= 2
      stop_totally
    end
    
    def climb_down
      land if jumping?
      @climbing = true
      suspend_gravity
      self.y += 2
      stop_totally
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

    # Return the Platform we're standing on or nil.
    def standing_on_platform
      return nil if falling? or jumping?
      what_object_hit_me_on_the :side => :bottom, :restrict => Standable, :look_ahead => 10, :margin_of_error => 25
    end

    # Like standing_on_platform but to be used when falling.
    def hit_floor
      return nil if rising?
      what_object_hit_me_on_the :side => :bottom, :restrict => Standable, :look_ahead => 10, :margin_of_error => 25
    end

    def hit_step
      return nil unless walking?
      return nil if jumping?
      what_object_hit_me_on_the :side => self.facing, :restrict => Standable, :look_ahead => 10, :margin_of_error => 25
    end

    # example usage: which_object_hit_me_on_the :side => :left, :restrict => Hangable, :look_ahead => 10, :margin_of_error => 25
    def what_object_hit_me_on_the(options)
      options[:look_ahead] ||= -10
      options[:margin_of_error] ||= 20
      options[:restrict] ||= Class
      axis = :x
      object_edge = :left
      case options[:side]
      when :left
        options[:look_ahead] = -options[:look_ahead].abs
        object_edge = :right
      when :right
        options[:look_ahead] = options[:look_ahead].abs
        object_edge = :left
      when :top
        axis = :y
        options[:look_ahead] = -options[:look_ahead].abs
        object_edge = :bottom
      when :bottom
        axis = :y
        options[:look_ahead] = options[:look_ahead].abs
        object_edge = :top
      end
      if axis == :y
        self.y += options[:look_ahead]
      else
        self.x += options[:look_ahead]
      end
      block = hit_objects.select do |o| 
        o.is_a? options[:restrict] and o.bb.send(object_edge).between?(self.bb.send(options[:side]) - options[:margin_of_error], self.bb.send(options[:side]) + options[:margin_of_error]) 
      end.first # Note: should this be first or last?
      if axis == :y
        self.y -= options[:look_ahead]
      else
        self.x -= options[:look_ahead]
      end
      block
    end

    def hit_hangable
      return nil unless self.is_a? Player
      return nil unless jumping? or hanging? or edging?
      what_object_hit_me_on_the :side => :top, :restrict => Hangable, :look_ahead => 5, :margin_of_error => 10
    end

    def hit_edge
      return nil unless self.is_a? Player
      return nil unless jumping? or hanging? or edging?
      what_object_hit_me_on_the :side => self.facing, :restrict => Hangable, :look_ahead => 5, :margin_of_error => 15
    end

    def hit_ceiling
      return nil unless rising?
      block = hit_objects.select do |o|
        o.is_a? Unpassable
      end.last
    end

    def facing_toward(object)
      margin_of_error = 25
      face = false
      # FIXME: add vertical sight range (test it, anyway)
      face = true if facing_right? and object.x > self.x #and object.y.between?(self.bb.bottom + margin_of_error, self.bb.top - margin_of_error)
      face = true if facing_left? and object.x < self.x #and object.y.between?(self.bb.bottom + margin_of_error, self.bb.top - margin_of_error)
      face
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
      future_distance = 5
      self.y -= 2 # Prevent hitting the floor.
      left_thing = what_object_hit_me_on_the :side => :right, :restrict => Unpassable, :look_ahead => 5, :margin_of_error => 25
      right_thing = what_object_hit_me_on_the :side => :left, :restrict => Unpassable, :look_ahead => 5, :margin_of_error => 25
      self.y += 2
      left_thing || right_thing
    end

    # Return true if we support movement states and we're aware of something
    # amiss.
    def alert?
      return true if self.respond_to? :has_movement_state? and (has_movement_state?(:alert) or has_movement_state?(:noticed))
      false
    end


    def update_animation
      if stopping?
        @image = next_animation_frame(:stopping)
      elsif jumping?
        @image = next_animation_frame(:jump)
      elsif walking? and not climbing?
        if alert?
          @image = next_animation_frame(:alert)
        else
          @image = next_animation_frame(:walk)
        end
      elsif hanging? and not edging?
        if [self.x, self.y] != @previous_position
          @image = next_animation_frame(:hang)
        end
      elsif edging?
        if [self.x, self.y] != @previous_position
          @image = next_animation_frame(:climb)
        end
      elsif climbing?
        if [self.x, self.y] != @previous_position
          @image = next_animation_frame(:climb)
        end
      elsif @facing != @previous_facing
        if alert?
          @image = next_animation_frame(:alert)
        else
          @image = next_animation_frame(:stand)
        end
      else
          @image = next_animation_frame(:stand)
      end
      @previous_facing = @facing
      @previous_position = [self.x, self.y]
    end

    def next_animation_frame(tag)
      image = @animation.next unless @animation[tag]
      image = @animation[tag] if @animation[tag].is_a? Gosu::Image
      image = @animation[tag].next if image.nil?
      self.factor_x = -1 if facing_left?
      self.factor_x = 1 if facing_right?
      image
    end


    def update
      # Make sure we stop after slowing down.
      stop_totally if @velocity_x != 0 and @velocity_x.between?(-0.2, 0.2)
      stop_totally if sliding?

      # Allows us to climb stairs automatically (without jumping).
      if floor = hit_step
        self.y = floor.bb.top - 1
        land
      end

      # This will be called constantly while on the ground, which is fine.
      if floor = hit_floor
        self.y = floor.bb.top - 1
        land
      end

      # FIXME: add a way to climb around the outside of a platform (top to edge,
      # edge to bottom, etc.)
      just_hung = false
      if ceil = hit_hangable
        hang
        just_hung = true
      elsif ceil = hit_edge
        edge_hang
        just_hung = true
      elsif ceil = hit_ceiling
        self.y = ceil.bb.bottom + self.image.height
        self.velocity = 0
      end

      if walking? and fallen_off_platform?
        @prevent_falling.call if @prevent_falling
      end

      background_obj = self.background_object

      if not hanging? and not edging? and block = hit_obstacle?
        self.x = previous_x
        handle_hit_obstacle(block) 
      end

      if just_hung
        just_hung = false
      elsif hanging?
        land unless hit_hangable or hit_edge
      else
        land if climbing? and not background_obj
      end

      background_obj.activate(self) if background_obj

      update_animation

      if game_state.viewport.outside?(self)
        if fallen_off_bottom?
          # FIXME: this does not work because jumping up sets your Y coord to a
          # huge number for some reason.
          #handle_fell_off_screen
          self.y = previous_y
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

