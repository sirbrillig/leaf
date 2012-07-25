module Leaf
  class LevelEditor < Chingu::GameStates::Edit
    def setup
      super
      editable_game_objects.each { |object| object.show! if object.respond_to? :show! }
      on_input(:n, :toggle_snap_to_grid)
    end

    def toggle_snap_to_grid
      @snap_to_grid = !@snap_to_grid
    end

    def draw_toolbar_objects
      x = 20
      y = 60
      @classes.each do |klass|
        puts "Creating a #{klass}"  if @debug

        # We initialize x,y,zorder,rotation_center after creation
        # so they're not overwritten by the class initialize/setup or simular
        begin
          game_object = klass.create(:paused => true)
          game_object.x = x + 30
          game_object.y = y
          game_object.options[:toolbar] = true
          game_object.rotation_center = :center_center
          game_object.alpha = 255

          # Scale down object to fit our toolbar
          if game_object.image
            Text.create("#{klass.name.split('::').last.to_s[0..9]}\n#{game_object.width.to_i}x#{game_object.height.to_i}", :size => 18, :x=>x-16, :y=>y+28, :max_width => 100, :rotation_center => :top_left, :align => :center, :factor => 1)
            game_object.factor = 0.7
            x += 80
          else
            puts "Skipping #{klass} - no image" if @debug
            game_object.destroy
          end
        rescue
          puts "Couldn't use #{klass} in editor: #{$!}"
        end
      end        
    end
  end # LevelEditor
end # Leaf
