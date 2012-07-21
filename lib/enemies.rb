module Leaf
  class Enemy < Creature
    def setup
      super
      load_animation
      @image = @animation.first

      @speed = 1
      @stop = true
      @headed_left = true
      @no_waiting = false
      @started = false
    end

    def update
      super
      # We don't start moving until we're on-screen.
      if (not @started) and game_state.viewport.inside?(self)
        start_movement 
        @started = true
      end
      self.hide!
      kill_players
    end

    # Check to see if we've killed any players.
    def kill_players
      self.each_collision(Player) do |enemy, player|
        game_state.died
      end
    end

    # Take a step.
    def walk
      return unless game_state.viewport.inside?(self)
      return if stopped?
      if @headed_left
        move_left
      else
        move_right
      end
    end

    def turn_around
      @headed_left = !@headed_left
    end

    def stopped?
      @stop
    end

    def stop
      @stop = true
    end

    def go
      @stop = false
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
    def load_animation
      @animation = Animation.new(:file => "media/guard.png", :size => 50)
      @animation.frame_names = {:face_right => 0..1, :face_left => 2..3}
    end

    def start_movement
      go
    end

    def update
      super
      walk
    end

    def handle_hit_obstacle
      turn_around
    end

    def handle_fell_off_platform
      turn_around
    end
  end # Guard


  class Watcher < Enemy
    def start_movement
      @speed = 1
      @no_waiting = true
      @noticed = false
    end

    def load_animation
      @animation = Animation.new(:file => "media/watcher.png", :size => 50)
    end

    def noticed_player
      go
      @noticed = true
    end

    def update
      super
      if not stopped? and not @noticed
        if game_state.player.x > self.x
          move_right
        else
          move_left
        end
        stop
      end
    end

    def handle_hit_obstacle
      jump
      land
    end

    def jump
      return if stopped?
      super
    end

    def handle_fell_off_platform
      jump
      land if jumping?
    end
  end # Watcher


  class Walker < Watcher
    def load_animation
      @animation = Animation.new(:file => "media/walker.png", :size => 50)
    end

    def start_movement
      go
    end

    def update
      super
      if not stopped?
        if not @noticed
          move_left
        else
          @speed = 1.5
          if game_state.player.x > self.x
            move_right
          else
            move_left
          end
          stop
        end
      end
    end

    def handle_fell_off_platform
    end
  end # Walker

end # Leaf
