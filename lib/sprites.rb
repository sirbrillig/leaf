module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1#, :debug => true

    def setup
      @image = Gosu::Image["media/platform.png"]
      self.zorder = Leaf::Level::PLATFORM_LAYER
      self.rotation_center = :top_right 
    end

  end # Platform


  class Enemy < Creature
    trait :bounding_box, :scale => 1#, :debug => true

    def setup
      super
      @animation = Animation.new(:file => "media/enemy.png", :size => 50)
      @image = @animation.first

      @speed = 2
      @stop = false
      @headed_left = true
      self.hide!
      start_movement
    end

    def update
      hide!
      if game_state.viewport.inside?(self)
        if stopped?
          every(100, :name => 'waiting', :preserve => true) { @image = @animation.next }
        else
          stop_timer('waiting')
          if @headed_left
            move_left
          else
            move_right
          end
        end
      end

      self.each_collision(Player) do |enemy, player|
        #stop
      end
    end

    def start_movement
      every(2500, :name => 'pacing') { turn_around }
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


  class Player < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/player.png", :size => 50)
      @image = @animation.first

      @visible_area = VisibleArea.create(:x => self.x, :y => self.y)

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:holding_up, :holding_w], :jump)
    end

    def update
      @visible_area.follow(self) if @visible_area
    end
  
    def fell_off_screen
      exit
    end
  end # Player


  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1#, :debug => true
    def setup
      self.zorder = Leaf::Level::BACKGROUND_LAYER
      self.rotation_center = :center
      @image = Gosu::Image["media/visiblearea.png"]
      self.alpha = 50
    end

    def follow(sprite)
      self.x = sprite.x
      self.y = sprite.y
    end

    def update
      self.each_collision(Enemy) do |area, enemy|
        enemy.show!
      end
    end

  end # VisibleArea

end # Leaf
