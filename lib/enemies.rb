module Leaf
  class Enemy < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/enemy.png", :size => 50)
      @image = @animation.first

      @speed = 1
      @stop = false
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
  end # Enemy
end # Leaf
