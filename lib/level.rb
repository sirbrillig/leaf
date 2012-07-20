module Leaf
  class Level < Chingu::GameState
    traits :viewport, :timer
    attr_reader :player, :game_object_map

    SPRITES_LAYER = 100
    PLATFORM_LAYER = 15
    LIGHTED_LAYER = 10
    BACKGROUND_OBJECT_LAYER = 8
    BACKGROUND_LAYER = 5

    FAR_OBJECT_ALPHA = 50
    MIDDLE_OBJECT_ALPHA = 100
    CLOSE_OBJECT_ALPHA = 255

    def initialize(options={})
      super

      on_input(:e, :edit)
      on_input(:escape, :exit)
      on_input(:q, :exit)

      self.viewport.game_area = [0, 0, 2048, 768]

      @file = File.join("maps/#{self.class.name.split('::').last.to_s.downcase}.yml")
      load_game_objects(:file => @file, :debug => Leaf::DEBUG)

      @background = Leaf::Background.create(:x => 900, :y => 200)

      @player = Leaf::Player.create(:x => 70, :y => 100)

      @grid = [50, 50]
      self.viewport.lag = 0.95
    end

    def setup
      @game_object_map = Chingu::GameObjectMap.new(:game_objects => Platform.all, :grid => @grid)
    end

    def edit
      push_game_state(Chingu::GameStates::Edit.new(:grid => @grid, :file => @file, :snap_to_grid => true, :except => [Player, Creature, Enemy, VisibleArea]))
    end

    def draw
      #fill(Gosu::Color::BLACK)
      super
    end

    def update
      super
      self.viewport.x_target = @player.x - $window.width/2
      $window.caption = "Leaf"
    end

    def died
      push_game_state(Leaf::GameOver)
    end

    # Return the distance between two points A and B on the x/y grid. 
    def distance(a, b)
      Math.sqrt(((a.x - b.x) ** 2) + ((a.y - b.y) ** 2).abs)
    end
  end # Level

class Level1 < Level; end
class Level2 < Level; end

end # Leaf

