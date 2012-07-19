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
      game_state.died
    end
  end # Player


  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1.1, :debug => Leaf::DEBUG
    def setup
      self.zorder = Leaf::Level::BACKGROUND_LAYER
      self.rotation_center = :center
      @image = Gosu::Image["media/visiblearea.png"]
      self.alpha = 40
    end

    def follow(sprite)
      self.x = sprite.x
      self.y = sprite.y
    end

    def update
      self.each_collision(Guard, Walker) do |area, enemy|
        enemy.show!
      end
    end

  end # VisibleArea

end # Leaf
