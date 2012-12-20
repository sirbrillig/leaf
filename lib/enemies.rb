module Leaf
  class Enemy < Creature
    include Hidable
    include MovementBehaviors
    include MovementStates

    def setup
      super
      load_animation
      @image = @animation.first

      self.speed = 1
      @headed_left = true
      @started = false
      @hidden = true
      self.alpha = 255

      @prevent_falling = Proc.new { turn_around }
    end

    def update
      super
      # We don't start moving until we're on-screen.
      if (not @started) and game_state.viewport.inside?(self)
        start_movement 
        @started = true
      end
      play_next_movement if @started
      kill_players
      @hidden = true
    end

    def kill_players
      raise "More than one Player found." if Player.size > 1
      each_collision(Player) { game_state.died }
    end

    # Start walking in the direction we're facing (using headed_left).
    def walk
      if @headed_left
        move_left
      else
        move_right
      end
    end

    # Stop, turn around, and start walking again.
    def turn_around
      stop_totally
      @headed_left = !@headed_left
      walk
    end


    def noticed_player
      # FIXME: add more dramatic notification, eg: screen shake, things turn
      # red, etc.
      add_movement_state(:noticed)
    end

    def outside_notice
      start_alert if has_movement_state? :noticed
      remove_movement_state(:noticed)
    end

    # Sets us to alert status and starts a timer to turn it off.
    def start_alert
      add_movement_state(:alert)
      after(5000) { remove_movement_state :alert }
    end

    # Override to set @animation.
    def load_animation
      @animation = Chingu::Animation.new(:file => "media/blank.png", :size => 50)
    end

    # Override to provide custom init code.
    def start_movement
    end

#     def handle_hit_obstacle(object)
#       turn_around if object.is_a? Unpassable and not alert?
#     end
  end # Enemy


  class Guard < Enemy
    def setup
      super
      define_movement do
        walk_left_for 2.seconds
        look_left_for random_period
        look_right_for random_period
        look_left_for 0.5.seconds
        walk_right_for 2.seconds
        look_left_for random_period
        look_right_for random_period
        look_right_for 0.5.seconds
        #FIXME: add alert state separate from noticed.
        if_noticed do
          set_speed_to 2
          ignore_falling
          #walk_toward_target(game_state.player) #FIXME: why does passing this fail to pass anything? ah, because of context when this block was created?
#           walk_toward_player_for 0.2.seconds
        end
      end
    end

    def load_animation
      @animation = Chingu::Animation.new(:file => "media/guard.png", :size => 50)
      @animation.frame_names = {:stand => 0, :walk => 0..1, :alert => 4..5, :stopping => 0..1 }
    end

    def start_movement
    end
  end # Guard


  class Watcher < Enemy
    def setup
      super
      define_movement do
        look_left_for random_period
        look_right_for random_period
        if_noticed do
          ignore_falling
          walk_toward_player_for 0.2.seconds
        end
      end
    end

    def start_movement
      self.speed = 4
    end

    def load_animation
      @animation = Chingu::Animation.new(:file => "media/watcher.png", :size => 50)
      @animation.frame_names = {:stand => 0, :walk => 0..1, :alert => 0..1, :jump => 2..3, :stopping => 0..1 }
    end
  end # Watcher

end # Leaf
