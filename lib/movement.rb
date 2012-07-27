module Leaf
  module MovementBehaviors
    attr_accessor :movement_behaviors, :noticed_behaviors

    def define_movement(&block)
      self.movement_behaviors = []
      block.call
    end

    def if_noticed(&block)
      self.noticed_behaviors = []
      @recording_noticed_behavior = true
      block.call
      @recording_noticed_behavior = false
    end

    def play_next_movement
      # Silently fail if no movements are defined.
      return if self.movement_behaviors.nil? or self.movement_behaviors.empty?
      behavior_array = self.movement_behaviors
      behavior_array = self.noticed_behaviors if @noticed and not self.noticed_behaviors.nil?
      rotate_behaviors if behavior_array.first.complete?
      behavior_array.first.run unless behavior_array.first.executed?
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_right_for(ms)
      behavior = MovementBehavior.create { move_right }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_left_for(ms)
      behavior = MovementBehavior.create { move_left }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def look_right_for(ms)
      behavior = MovementBehavior.create { @facing = :right }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def look_left_for(ms)
      behavior = MovementBehavior.create { @facing = :left }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_toward_player_for(ms)
      behavior = MovementBehavior.create do
        if game_state.player.x > self.x
          move_right
        else
          move_left
        end
      end
      behavior.at_end { stop_moving }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    private
    def rotate_behaviors
      if @noticed and not self.noticed_behaviors.nil?
        self.noticed_behaviors.push(self.noticed_behaviors.shift)
      else
        self.movement_behaviors.push(self.movement_behaviors.shift)
      end
    end

    private
    def record_behavior(behavior)
      raise "Must be called inside define_movement block" if self.movement_behaviors.nil?
      if @recording_noticed_behavior
        raise "Must be called inside if_noticed block" if self.noticed_behaviors.nil?
        @noticed_behaviors << behavior
      else
        @movement_behaviors << behavior
      end
    end
  end


  class MovementBehavior < Chingu::BasicGameObject
    trait :timer
    attr_accessor :action
    question_accessor :complete
    question_accessor :executed

    def initialize(&block)
      super
      @action = block
    end

    def at_end(&block)
      @at_end_block = block
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def completed_after(ms)
      @complete_block = Proc.new do
        time = ms
        time = rand(3.seconds) if ms == :random_period
        after(time) do 
          @at_end_block.call if @at_end_block
          self.complete = true
          self.executed = false
        end
      end
    end
    
    def run
      @complete_block.call if @complete_block
      @action.call if @action
      self.executed = true
      self.complete = false
    end
  end # MovementBehavior
end # Leaf
