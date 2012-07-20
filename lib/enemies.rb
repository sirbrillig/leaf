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
      if game_state.viewport.inside?(self) and not @started
        start_movement 
        @started = true
      end
      self.hide!
      handle_each_update if @started
      kill_players
    end

    # Check to see if we've killed any players.
    def kill_players
      self.each_collision(Player) do |enemy, player|
        game_state.died
      end
    end

    # Walk back and forth or hang out if stopped. Actually, if you don't call
    # turn_around, we will only walk in one direction.
    def pace
      if game_state.viewport.inside?(self)
        if stopped?
          every(100, :name => 'waiting', :preserve => true) { @image = @animation.next } unless @no_waiting
        else
          stop_timer('waiting')
          if @headed_left
            move_left
          else
            move_right
          end
        end
      end
    end

    # Override to set @animation.
    def load_animation
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
    end

    # Override to provide custom init code.
    def start_movement
    end

    # Override to provide custom movement code.
    def handle_each_update
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
  end # Enemy

  class Guard < Enemy
    def load_animation
      @animation = Animation.new(:file => "media/enemy.png", :size => 50)
      @image = @animation.first
    end

    def start_movement
      go
    end

    def handle_each_update
      pace
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
      @image = @animation.first
    end

    def noticed_player
      go
      @noticed = true
    end

    def handle_each_update
      if not stopped?
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
      @image = @animation.first
    end

    def start_movement
      go
    end

    def handle_each_update
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
