require 'gosu'
require_relative 'defstruct'

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@scroll_x = 0
		@background = Gosu::Image.new(self, 'images/ocean.jpg', false)
		@foreground = Gosu::Image.new(self, 'images/fish.png', true)
	end

	def button_down(button)
 		close if button == Gosu::KbEscape
  end

  def update
  	@scroll_x += 3
  	if @scroll_x > @foreground.width
  		@scroll_x = 0
  	end
  end

	def draw
		@background.draw(0, 0, 0)
		@foreground.draw(@scroll_x, 290, 0)
		@foreground.draw(@scroll_x - @foreground.width, 290, 0)
	end
end

window = GameWindow.new(1800, 1080, false)
window.show