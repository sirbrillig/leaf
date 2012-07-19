module Leaf
  class Enemy < Creature
    def setup
      super
      load_animation

      @speed = 1
      @stop = true
      @headed_left = true
      start_movement
    end

    def fell_off_platform
      turn_around
    end

    def update
      self.hide!
      if game_state.viewport.inside?(self)
        if stopped?
          every(100, :name => 'waiting', :preserve => true) { @image = @animation.next }
        else
          stop_timer('waiting')
          pace
        end
      end

      self.each_collision(Player) do |enemy, player|
        game_state.died
      end
    end

    def pace
      if @headed_left
        move_left
      else
        move_right
      end
    end

    # Override to set @animation and @image.
    def load_animation
      @animation = Animation.new(:file => "media/blank.png", :size => 50)
      @image = @animation.first
    end

    # Override to provide custom walking code.
    def start_movement
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
  end # Guard

  class Walker < Enemy
    def load_animation
      @animation = Animation.new(:file => "media/walker.png", :size => 50)
      @image = @animation.first
    end

    def start_movement
      go
    end

    def fell_off_platform
    end
  end # Walker
end # Leaf
