require 'gosu'
require_relative 'defstruct'
require_relative 'vector'
require_relative 'timer'
require_relative 'animation'

PLAYER_ANIMATION_FPS = 1.0 # frames/second
GRAVITY = Vec[0, 50] # pixels/s^2
JUMP_VEL = Vec[0, -50] # pixel/s
DEATH_VELOCITY = Vec[50, -500] # pixels/s
DEATH_ROTATIONAL_VEL = 360 # degrees/s
RESTART_INTERVAL = 3 #seconds
PLAYER_FRAMES = [:player, :player1]
OBSTACLE_PADDING = 150 #px
DIFFICULTIES = {
  easy: {
    speed: 150, # pixels/s
    obstacle_gap: 500, # pixels
    obstacle_spawn_interval: 3.0, # secs
  },
  medium: {
    speed: 200, # pixels/s
    obstacle_gap: 380, #pixels
    obstacle_spawn_interval: 1.3, #seconds
  },
  hard: {
    speed: 400, # pixels/s
    obstacle_gap: 260, # pixels
    obstacle_spawn_interval: 1.0, #seconds
  },
}

Rect = DefStruct.new{{
  pos: Vec[0,0], #x, y
  size: Vec[0,0], #width, height
  
}}.reopen do
  def min_x; pos.x; end
  def min_y; pos.y; end
  def max_x; pos.x + size.x; end
  def max_y; pos.y + size.y; end
end

Obstacle = DefStruct.new{{
  pos: Vec[0,0],
  player_has_crossed: false,
  gap: DIFFICULTIES[:easy][:obstacle_gap],
}}

Particle = DefStruct.new{{
  pos: Vec[0, 0],
  velocity: Vec[0.0],
  rotation: 0,
  rotational_velocity: 0,
  scale: 1.0, 
  tint: Gosu::Color::WHITE,
  }}

GameState = DefStruct.new{{
  difficulty: :medium,
  score: 0,
  started: false,
  alive: true,
  scroll_x: 0,
  player_pos: Vec[150,250],
  player_vel: Vec[0,0],
  player_rotation: 0,
  player_animation: Animation.new(PLAYER_ANIMATION_FPS, PLAYER_FRAMES),
  player_frame: 0, 
  player_frame_remaining: 1.0/PLAYER_ANIMATION_FPS,
  obstacles: [], # array of Obstacle
  # obstacle_countdown: OBSTACLE_SPAWN_INTERVAL,
  particles: [],
  obstacle_timer: Timer::Looping.new(DIFFICULTIES[:medium][:obstacle_spawn_interval]),
  restart_timer: Timer::OneShot.new(RESTART_INTERVAL),
}}



class GameWindow < Gosu::Window
  # SAVE_PATH = ENV['HOME'] + '/.ggj_save'
  def initialize(*args)
    super
    @font = Gosu::Font.new(self, Gosu.default_font_name, 40)
    @images = {
			background: Gosu::Image.new(self, 'images/ocean.jpg', false),
			foreground: Gosu::Image.new(self, 'images/foreground.png', true),
      trump: Gosu::Image.new(self, 'images/trump.png', false),
			player: Gosu::Image.new(self, 'images/nemo_forward.png', false),
      player1: Gosu::Image.new(self, 'images/nemo.png', false),
			obstacle: Gosu::Image.new(self, 'images/avatar.png', false),
      particle: Gosu::Image.new(self, 'images/soundwaves.png', false),
      # golf ball
      fish_1: Gosu::Image.new(self, 'images/fish.png', false),
      angel: Gosu::Image.new(self, 'images/angel.png', false),
      submarine: Gosu::Image.new(self, 'images/submarine.png', false),
      spaceship: Gosu::Image.new(self, 'images/spaceship.png', false),

		}

    @sounds = {
      flap: Gosu::Sample.new(self, 'audio/bubble.wav'),
      score: Gosu::Sample.new(self, 'audio/score.ogg'),
      high_score: Gosu::Sample.new(self, 'audio/whale_short.wav'),
      #death 
    }
    @state = GameState.new

    @music = Gosu::Song.new(self, 'audio/music.mp3')
    @music.play
  end

  def button_down(button)
    case button
    when Gosu::KbEscape then close
    when Gosu::Kb1 then set_difficulty(:easy)
    when Gosu::Kb2 then set_difficulty(:medium)
    when Gosu::Kb3 then set_difficulty(:hard)
    when Gosu::KbSpace
      if @state.alive
        @state.player_vel.set!(JUMP_VEL) if @state.alive
        @sounds[:flap].play(0.2, rand(0.9..1.1))
      end
      @state.started = true
    end
  end

  def set_difficulty(name)
    @state.difficulty = name
    @state.obstacle_timer.interval = DIFFICULTIES[name][:obstacle_spawn_interval]
  end

  def save_game
    File.binwrite(SAVE_PATH, Marshal.dump(@state))
  end

  def load_game
    @state = Marshal.load(File.binread(SAVE_PATH))
  end

  def update
    dt = update_interval / 1000.0

    @state.scroll_x += dt*difficulty[:speed]*0.5
    if @state.scroll_x > @images[:foreground].width
      @state.scroll_x = 0
    end

    @state.player_animation.update(dt)

    @state.particles.each do |part|
      part.velocity += dt*GRAVITY
      part.pos += dt*part.velocity
      part.rotation += dt*part.rotational_velocity
    end
    @state.particles.reject! { |parts| parts.pos.y >= height }

    return unless @state.started

    @state.player_vel += dt*GRAVITY
    @state.player_pos += dt*@state.player_vel

    if @state.alive
      
      @state.obstacle_timer.update(dt) do
        gap =  difficulty[:obstacle_gap]
        lower_bound = height - OBSTACLE_PADDING - gap
        @state.obstacles << Obstacle.new(
          pos: Vec[width, rand(OBSTACLE_PADDING..lower_bound)],
          gap: gap,
          )
      end
    end

    @state.obstacles.each do |obst|
      obst.pos.x -= dt*difficulty[:speed]
      if obst.pos.x < @state.player_pos.x && !obst.player_has_crossed && @state.alive
        if @state.score > 5
          @sounds[:high_score].play(0.8, 0.8)
        else
          @sounds[:score].play(0.8, 0.8 + (@state.score * 0.1))
        end
          # @sounds[:score].play(0.8, 0.8 + (@state.score * 0.1))
       
        @state.score += 1
        obst.player_has_crossed = true
        particle_burst
      end
    end

    @state.obstacles.reject! { |obst| obst.pos.x < -@images[:obstacle].width }

    if @state.alive && player_is_colliding?
      @state.alive = false
      @state.player_vel.set!(DEATH_VELOCITY)
    end

    unless @state.alive
      @state.player_rotation += dt*DEATH_ROTATIONAL_VEL
      @state.restart_timer.update(dt) { restart_game }
    end
  end

  def particle_burst
    30.times do
      @state.particles << Particle.new(
        pos: Vec[width/2.0, 60],
        velocity: Vec[rand(-100..100), rand(-300..-10)],
        rotation: rand(0..360),
        rotational_velocity: rand(-360..360),
        scale: rand(0.5..1.0),
        tint: Gosu::Color.new(
          255,
          rand(150..255),
          rand(150..255),
          rand(150..255),
        ),
      )
    end
  end

  def restart_game
    old_difficulty = @state.difficulty
    @state = GameState.new(scroll_x: @state.scroll_x)
    set_difficulty(old_difficulty)
  end

  def player_is_colliding?
    player_r = player_rect    
    obstacle_rects.find { |obst_r| rects_insterct?(player_r, obst_r) }
  end

  def rects_insterct?(r1, r2)
    return false if r1.max_x < r2.min_x
    return false if r1.min_x > r2.max_x

    return false if r1.min_y > r2.max_y
    return false if r1.max_y < r2.min_y

    true
  end

  def draw
    
    @images[:background].draw(0, 0, 0)
    
    @state.particles.each do |part|
      @images[:particle].draw_rot(
        part.pos.x, part.pos.y, 0,
        part.rotation,
        0.5, 0.5,
        part.scale, part.scale,
        part.tint,
      )
    end
    @images[:foreground].draw(-@state.scroll_x, 0, 0)
    @images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 0, 0)

    @state.obstacles.each do |obst|
      img_y = @images[:obstacle].height 
      # top log
      @images[:obstacle].draw(obst.pos.x, obst.pos.y - img_y, 0)
      scale(1, -1) do
        # bottom log
        @images[:obstacle].draw(obst.pos.x, - height - img_y + (height - obst.pos.y - obst.gap), 0)
      end
    end

    player_frame.draw_rot(
      @state.player_pos.x, @state.player_pos.y,
      0, @state.player_rotation,
      0, 0)

    if @state.score > 8
      @images[:fish_1].draw(-@state.scroll_x, 0, 0)
      @images[:fish_1].draw(-@state.scroll_x + @images[:fish_1].width, 0, 0)
    end

    if @state.score > 15
      @images[:trump].draw(1320, 920, 0)
    end

    if @state.score > 12
      @images[:submarine].draw(820, 920, 0)
    end

    if @state.score > 20
      @images[:spaceship].draw(1320, 320, 0)
    end



    @font.draw_rel(@state.score.to_s, width/2.0, 60, 0, 0.5, 0.5)
    @font.draw_rel(@state.difficulty.to_s, width - 10, height - 10, 0, 1.0, 1.0) 

    #debug_draw
  end

  def difficulty
    DIFFICULTIES[@state.difficulty]
  end

  def player_frame
     @images[@state.player_animation.frame]
  end

  def player_rect
    Rect.new(
      pos: @state.player_pos,
      size: Vec[player_frame.width, player_frame.height]
    )
  end

  def obstacle_rects
    img_y = @images[:obstacle].height 
    obst_size = Vec[@images[:obstacle].width, @images[:obstacle].height]

    @state.obstacles.flat_map do |obst|
      top = Rect.new(pos: Vec[obst.pos.x, obst.pos.y - img_y], size: obst_size)
      bottom = Rect.new( pos: Vec[obst.pos.x, obst.pos.y + obst.gap], size: obst_size)
      [top, bottom]
    end
  end

  def debug_draw
    color = player_is_colliding? ? Gosu::Color::RED : Gosu::Color::GREEN

    draw_debug_rect(player_rect, color) 
    obstacle_rects.each do |obst_rect|
      draw_debug_rect(obst_rect)
    end
  end

  def draw_debug_rect(rect, color = Gosu::Color::GREEN)
    x = rect.pos.x
    y = rect.pos.y
    w = rect.size.x
    h = rect.size.y

    points = [
      Vec[x, y],
      Vec[x + w, y],
      Vec[x + w, y + h],
      Vec[x, y + h]
    ]

    points.each_with_index do |p1, idx|
      p2 = points[(idx + 1) % points.size]
      draw_line(p1.x, p1.y, color, p2.x, p2.y, color)
    end
  end
end

window = GameWindow.new(1920, 1080, false)
window.show
