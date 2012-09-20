module Leaf

  class Player < Creature
    PARTIAL_COVER_ALPHA = 160

    def setup
      super
      @animation = Animation.new(:file => "media/sprite3_default.png", :width => 40, :height => 64)
      @animation.frame_names = {
        :stand => 0..2,
        :climb => 3..4,
        :jump => 3..4,
        :hang => 3..4,
        :stopping => 0..2,
      }
      @image = @animation.first
      @partial_cover = false

      @visible_area = DetectionArea.create(:x => self.x, :y => self.y)
      @visible_area.holder = self
      @visible_area.handle_seen_close = Proc.new do |object| 
        object.noticed_player if @partial_cover == false and object.respond_to? :noticed_player
        object.outside_notice if @partial_cover and object.respond_to? :outside_notice 
      end
      @visible_area.handle_seen_middle = Proc.new do |object| 
        object.noticed_player if @partial_cover == false and object.respond_to? :noticed_player
        object.outside_notice if @partial_cover and object.respond_to? :outside_notice 
      end
      @visible_area.handle_collide_distant = Proc.new { |object| object.outside_notice if object.respond_to? :outside_notice }

      on_input([:holding_left, :holding_a], :move_left)
      on_input([:holding_right, :holding_d], :move_right)
      on_input([:released_right, :released_d], :stop_moving)
      on_input([:released_left, :released_a], :stop_moving)
      on_input([:holding_up, :holding_w], :up_pressed)
      on_input([:holding_down, :holding_s], :down_pressed)
      on_input(:space, :fire_pressed)
    end

    def fire_pressed
      bomb = SmokeBomb.create(:x => self.x, :y => self.y)
      bomb.start_object = self
      bomb.activate
    end

    def up_pressed
      if edging?
        climb_up
      end
      return if hanging?
      object = background_object
      if object and object.is_a? Climbable
        climb_up
      else
        jump
      end
    end

    def down_pressed
      object = background_object
      climb_down if object and climbing?
      return climb_down if edging?
      finish_climbing if hanging?
    end

    def delete_other_players
      Player.all.each do |player|
        player.destroy! unless player == self
      end
    end

    def update
      super
      delete_other_players
      @visible_area.follow(self) if @visible_area
      object = background_object
      @partial_cover = false
      @partial_cover = true if object and climbing?
      if @partial_cover
        unless @old_alpha
          @old_alpha = self.alpha
          self.alpha = PARTIAL_COVER_ALPHA
        end
      else
        if @old_alpha
          self.alpha = @old_alpha
          @old_alpha = nil
        end
      end
    end
  
    def handle_fell_off_screen
      game_state.died
    end
  end # Player
end # Leaf

