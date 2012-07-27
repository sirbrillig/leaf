module Leaf
  module MovementBehaviors
    attr_accessor :movement_behaviors

    def define_movement(&block)
      self.movement_behaviors = []
      block.call
      # I don't suppose this needs to do anything.
    end

    def play_next_movement
      return if self.movement_behaviors.nil? or self.movement_behaviors.empty?
      self.movement_behaviors.push(self.movement_behaviors.shift) if self.movement_behaviors.first.complete?
      self.movement_behaviors.first.run unless self.movement_behaviors.first.executed?
    end

    def walk_right_for(ms)
      behavior = MovementBehavior.create { move_right }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      @movement_behaviors << behavior
    end

    def walk_left_for(ms)
      behavior = MovementBehavior.create { move_left }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      @movement_behaviors << behavior
    end

    def look_right_for(ms)
      behavior = MovementBehavior.create { @facing = :right }
      behavior.completed_after(ms)
      @movement_behaviors << behavior
    end

    def look_left_for(ms)
      behavior = MovementBehavior.create { @facing = :left }
      behavior.completed_after(ms)
      @movement_behaviors << behavior
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

    def completed_after(ms)
      @complete_block = Proc.new do
        after(ms) do 
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