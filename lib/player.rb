module Leaf

  class Player < Creature
    def setup
      super
      @animation = Animation.new(:file => "media/player2.png", :size => 50)
      @animation.frame_names = {:face_right => 0..1, :face_left => 2..3, :climb => 4..5, :jump => 5}
      @image = @animation.first
      @partial_cover = false

      @visible_area = DetectionArea.create(:x => self.x, :y => self.y)
      @visible_area.handle_collide_close = Proc.new { |object| object.noticed_player if object.respond_to? :noticed_player }
      @visible_area.handle_collide_middle = Proc.new { |object| object.noticed_player if @partial_cover == false and object.respond_to? :noticed_player }

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:released_right, :released_d], :stop_moving)
      on_input([:released_left, :released_a], :stop_moving)
      on_input([:holding_up, :holding_w], :up_pressed)
      on_input([:holding_down, :holding_s], :down_pressed)
    end

    def up_pressed
      object = background_object
      if object and object.is_a? Climbable
        climb_up(object)
      else
        jump
      end
    end

    def down_pressed
      object = background_object
      climb_down(object) if object and climbing?
    end

    def update
      super
      @visible_area.follow(self) if @visible_area
      object = background_object
      @partial_cover = false
      @partial_cover = true if object and climbing?
    end
  
    def handle_fell_off_screen
      game_state.died
    end
  end # Player
end # Leaf

