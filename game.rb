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
			fish_1: Gosu::Image.new(self, 'images/fish.png', false),
			angel: Gosu::Image.new(self, 'images/angel.png', false),
			submarine: Gosu::Image.new(self, 'images/submarine.png', false),
			player: Gosu::Image.new(self, 'images/nemo_forward.png', false),
			obstacle: Gosu::Image.new(self, 'images/jellyfish.png', false),
			golf: Gosu::Image.new(self, 'images/golf.jpg', false),
			trump: Gosu::Image.new(self, 'images/trump.png', false),
		}

		@state = GameState.new

	end

	def button_down(button)
		case button
		when Gosu::KbEscape then close
 		when Gosu::KbSpace then @state.player_vel.set!(JUMP_VEL)
 		when Gosu::KbO then spawn_obstacle
 		end
  end

  def spawn_obstacle
  	@state.obstacles << Vec[width, 200]
  end

  def update
  	@state.scroll_x += 3
  	if @state.scroll_x > @images[:foreground].width
  		@state.scroll_x = 0
  	end

  	dt = update_interval / 1000.0

  	@state.player_vel += dt*GRAVITY
  	@state.player_pos += dt*@state.player_vel 

  	@state.obstacles.each do |obst|
  		obst.x -= 3
  	end
  end

	def draw
		@images[:background].draw(0, 0, 0)
		@images[:foreground].draw(-@state.scroll_x, 840, 0)
		@images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 840, 0)
		@images[:fish_1].draw(@state.scroll_x, 290, 0)
		@images[:fish_1].draw(@state.scroll_x - @images[:fish_1].width, 290, 0)
		@images[:angel].draw(@state.scroll_x, 210, 0)
		@images[:submarine].draw(@state.scroll_x - @images[:submarine].width, 510, 0)
		@images[:player].draw(50, @state.player_pos.y, 0)
		@state.obstacles.each do |obst|
			@images[:obstacle].draw(obst.x, -600, 0)
			@images[:obstacle].draw(obst.x, -height - 800, 0)
		end 
	end
end

window = GameWindow.new(1920, 1080, false)
window.show