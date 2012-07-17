module Leaf

  class Platform < Chingu::GameObject
    trait :collision_detection
    trait :bounding_box, :scale => 1, :debug => true

    def setup
      @image = Gosu::Image["platform.png"]
      self.zorder = 10
    end

  end # Platform


  class Player < Chingu::GameObject
    trait :bounding_box, :scale => 0.7, :debug => true
    traits :collision_detection, :timer, :velocity

    def setup
      @animation = Animation.new(:file => "player.png", :size => 50)
      @image = @animation.first

      on_input([:holding_left, :holding_a], :holding_left)
      on_input([:holding_right, :holding_d], :holding_right)
      on_input([:up, :w], :jump)

      @jumps = 0
      @speed = 4

      self.zorder = 1000
      self.acceleration_y = 0.5
      self.max_velocity = 20
      self.rotation_center = :bottom_center

      #self.factor = 0.5
    end

    def jumping?
      @jumps > 0
    end

    def falling?
      self.velocity_y > 0
    end

    def rising?
      self.velocity_y < 0
    end

    def holding_left
      move(-(@speed), 0)
    end

    def holding_right
      move(@speed, 0)
    end

    def jump
      return if @jumps == 1
      @jumps += 1
      self.velocity_y = -11
    end

    def land
      @jumps = 0
    end

    def land_on(platform)
      self.y = platform.bb.top - 1
      land
    end
    
    def hit_something?
      game_state.game_object_map.at(self.bb.centerx, self.bb.centery)
    end

    def hit_something_x?
      game_state.game_object_map.at(self.bb.centerx, self.bb.centery - 10) #FIXME
    end

    def hit_something_y?
      game_state.game_object_map.at(self.bb.centerx - 10, self.bb.centery) #FIXME
    end

    def move(x, y)
      #self.factor_x = self.factor_x.abs if x > 0
      #self.factor_x = -self.factor_x.abs if x < 0
      @image = @animation.next  if @animation # FIXME: only animate when moving.

      self.x += x
      if block = hit_something_x?
        self.x = previous_x
      end

      self.y += y
      if block = hit_something_y?
        if rising?
          puts "hit something going up: player = #{self.x},#{self.y}; block = #{block.x},#{block.y}"
          self.y = block.bb.bottom + self.height
        elsif falling?
          land_on(block)
        end
        self.velocity_y = 0
      end
    end

    def update
    end
  end # Player

end # Leaf
