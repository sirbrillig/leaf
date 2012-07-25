module Leaf
  class GameOver < Chingu::GameState
    def initialize(options={})
      super
      @white = Gosu::Color.new(255,255,255,255)
      @color = Gosu::Color.new(200,0,0,0)
      @font = Gosu::Font[64]
      @text = "GAME OVER/nPlay Again (y/n)?"

      on_input(:escape, :exit)
      on_input([:q, :n], :exit)
      on_input(:y, :restart)
    end

    def restart
      pop_game_state
      previous_game_state.reset_level
    end

    def draw
      previous_game_state.draw
      $window.draw_quad(0,0,@color, $window.width,0,@color, $window.width,$window.height,@color, 0,$window.height,@color, Chingu::DEBUG_ZORDER)
      @font.draw(@text, ($window.width/2 - @font.text_width(@text)/2), $window.height/2 - @font.height, Chingu::DEBUG_ZORDER + 1)
    end  
  end # GameOver
end # Leaf
