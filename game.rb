require 'gosu'
require_relative 'defstruct'
require_relative 'vector'

GRAVITY = Vec[0, 50] # pixels/s^2
JUMP_VEL = Vec[0, -50]

GameState = DefStruct.new{{ 
	scroll_x: 0,
	player_pos: Vec[0,0],
	player_vel: Vec[0,0],
	obstacles: [], #array of Vec
	}}

class GameWindow < Gosu::Window
	def initialize(*args)
		super
		@images = {
			background: Gosu::Image.new(self, 'images/ocean.jpg', true),
			foreground: Gosu::Image.new(self, 'images/foreground.png', false),
			player: Gosu::Image.new(self, 'images/nemo_forward.png', false),
			obstacle: Gosu::Image.new(self, 'images/jellyfish.png', false),
		}

		@state = GameState.new

	end

	def button_down(button)
 		close if button == Gosu::KbEscape
 		if button == Gosu::KbSpace 
 			@state.player_vel.set!(JUMP_VEL)
 		end
  end

  def update
  	@state.scroll_x += 3
  	if @state.scroll_x > @images[:foreground].width
  		@state.scroll_x = 0
  	end

  	dt = update_interval / 1000.0

  	@state.player_vel += dt*GRAVITY
  	@state.player_pos += dt*@state.player_vel 
  end

	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(-@state.scroll_x, 840, 0)
		@images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 840, 0)
		@images[:player].draw(50, @state.player_pos.y, 0)
		@images[:obstacle].draw(200, 800, 0)
		@images[:obstacle].draw(200, 100,0)
	end
end

window = GameWindow.new(1920, 1080, false)
window.show