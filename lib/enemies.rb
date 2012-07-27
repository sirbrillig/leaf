module Leaf
  class Enemy < Creature
    include Hidable
    include MovementBehaviors
    # FIXME: add movement DSL with an array of MovementBehaviors.
    # FIXME: add noise_while_walking that lights you up when walking.
    # FIXME: add separate movement array for noticed_player.
    # FIXME: add animation for noticed_player.

    def setup
      super
      load_animation
      @image = @animation.first

      self.speed = 1
      @headed_left = true
      @started = false
      @hidden = true
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
    end

    # Check to see if we've killed any players.
    def kill_players
      self.each_collision(Player) do |enemy, player|
        game_state.died
      end
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


    # Override to set @animation.
    def load_animation
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
    end

    # Override to provide custom init code.
    def start_movement
    end

  end # Enemy


  class Guard < Enemy
    def setup
      super
      define_movement do
        walk_left_for 2.seconds
        look_left_for 1.seconds
        look_right_for 1.seconds
        look_left_for 0.5.seconds
        walk_right_for 2.seconds
        look_right_for 1.seconds
        look_left_for 1.seconds
        look_right_for 0.5.seconds
      end
    end

    def load_animation
      @animation = Animation.new(:file => "media/guard.png", :size => 50)
      @animation.frame_names = {:face_right => 0..1, :face_left => 2..3}
    end

    def start_movement
    end

    def handle_hit_obstacle(object)
      turn_around if object.is_a? Unpassable
    end

    def handle_fell_off_platform
      turn_around
    end
  end # Guard


  class Watcher < Enemy
    def start_movement
      @noticed = false
      self.speed = 3
    end

    def load_animation
      @animation = Animation.new(:file => "media/watcher.png", :size => 50)
    end

    def noticed_player
      @noticed = true
    end

    def update
      super
      if @noticed and @started
        if game_state.player.x > self.x
          move_right
        else
          move_left
        end
        @noticed = false
      else
        stop_moving 
      end
    end

    def handle_hit_obstacle(object)
      #jump
      #land
    end

    def jump
      #return if stopped?
      #super
    end

    def handle_fell_off_platform
      #jump
      #land if jumping?
    end
  end # Watcher


  class Walker < Watcher
    def load_animation
      @animation = Animation.new(:file => "media/walker.png", :size => 50)
    end

    def start_movement
      walk
    end

    def update
      super
      if not stopped?
        if not @noticed
          move_left
        else
          self.speed = 1.5
          if game_state.player.x > self.x
            move_right
          else
            move_left
          end
          stop_moving
        end
      end
    end

    def handle_fell_off_platform
    end
  end # Walker

end # Leaf
