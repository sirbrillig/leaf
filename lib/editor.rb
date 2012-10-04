module Leaf
  class LevelEditor < Chingu::GameStates::Edit
    # FIXME: allow Undo function.
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

    def quit
      exit
    end

    def left_mouse_button
      @left_mouse_button  = true
      @selected_game_object = false

      if defined?(self.previous_game_state.viewport)
        @left_mouse_click_at = [self.previous_game_state.viewport.x + $window.mouse_x, self.previous_game_state.viewport.y + $window.mouse_y]
      else
        @left_mouse_click_at = [$window.mouse_x, $window.mouse_y]
      end

      # Put out a new game object in the editor window and select it right away
      @selected_game_object = copy_game_object(@cursor_game_object)  if @cursor_game_object

      # Check if user clicked on anything in the icon-toolbar of available game objects
      @cursor_game_object = game_object_icon_at($window.mouse_x, $window.mouse_y)

      # Get editable game object that was clicked at (if any)
      @selected_game_object ||= game_object_at(self.mouse_x, self.mouse_y)

      if @selected_game_object && defined?(self.previous_game_state.viewport)
        self.previous_game_state.viewport.center_around(@selected_game_object)  if @left_double_click
      end

      if @selected_game_object
        #
        # If clicking on a new object that's wasn't previosly selected
        #  --> deselect all objects unless holding left_shift
        #
        if @selected_game_object.options[:selected] == nil
          selected_game_objects.each { |object| object.options[:selected] = nil } unless holding?(:left_shift)
        end

        if holding?(:left_shift)
          @selected_game_object.options[:selected] = !@selected_game_object.options[:selected]
        else
          @selected_game_object.options[:selected] = true
        end

        #
        # Re-align all objects x/y offset in relevance to the cursor
        #
        selected_game_objects.each do |selected_game_object|
          selected_game_object.options[:mouse_x_offset] = selected_game_object.x - self.mouse_x
          selected_game_object.options[:mouse_y_offset] = selected_game_object.y - self.mouse_y
        end
      else
        deselect_selected_game_objects unless holding?(:left_shift)
      end
    end

  end # LevelEditor
end # Leaf
