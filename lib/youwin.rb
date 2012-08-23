module Leaf
  class YouWin < Chingu::GameState
    def setup
      @white = Gosu::Color.new(255,255,255,255)
      @color = Gosu::Color.new(200,0,0,0)
      @font = Gosu::Font[64]
      @text = "YOU WIN!"
      @text2 = "Play Again (y/n)?"

      on_input(:escape, :exit)
      on_input([:q, :n], :exit)
      on_input(:y, :start_over)
    end

    def start_over
      puts "starting level. Game states = #{game_states.join(', ')}"
      switch_game_state(Level2)
    end

    def draw
      previous_game_state.draw if previous_game_state
      $window.draw_quad(0,0,@color, $window.width,0,@color, $window.width,$window.height,@color, 0,$window.height,@color, Chingu::DEBUG_ZORDER)
      @font.draw(@text, ($window.width/2 - @font.text_width(@text)/2), $window.height/2 - @font.height, Chingu::DEBUG_ZORDER + 1)
      @font.draw(@text2, ($window.width/2 - @font.text_width(@text)/2), $window.height/2, Chingu::DEBUG_ZORDER + 1)
    end  
  end # YouWin
end # Leaf

