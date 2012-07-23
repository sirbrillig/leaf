module Leaf

  class Player < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/player2.png", :size => 50)
      @animation.frame_names = {:face_right => 0..1, :face_left => 2..3, :climb => 4..5, :jump => 5}
      @image = @animation.first

      @visible_area = DetectionArea.create(:x => self.x, :y => self.y)

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:released_right, :released_d], :stop_moving)
      on_input([:released_left, :released_a], :stop_moving)
      on_input([:holding_up, :holding_w], :up_pressed)
      on_input([:holding_down, :holding_s], :down_pressed)
    end

    def up_pressed
      return jump #FIXME: disabled climbing for testing
      object = on_background_object?
      if object and object.respond_to? :climb_height
        climb_up(object)
      else
        jump
      end
    end

    def down_pressed
      object = on_background_object?
      if object and climbing?
        climb_down(object)
      end
    end

    def update
      super
      @visible_area.follow(self) if @visible_area
    end
  
    def handle_fell_off_screen
      game_state.died
    end
  end # Player
end # Leaf

