require 'gosu'
require_relative 'defstruct'

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@images = {
			background: Gosu::Image.new(self, 'images/ocean.jpg', true),
			foreground: Gosu::Image.new(self, 'images/fish.png', false),
		}
		@scroll_x = 0
		
	end

	def button_down(button)
 		close if button == Gosu::KbEscape
  end

  def update
  	@scroll_x += 3
  	if @scroll_x > @images[:foreground].width
  		@scroll_x = 0
  	end
  end

	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(@scroll_x, 290, 0)
		@images[:foreground].draw(@scroll_x - @images[:foreground].width, 290, 0)
	end
end

window = GameWindow.new(1920, 1080, false)
window.show