#
# RSKit Sample Game - "THE APPLE CATCHER"
# (c)2006, yhara @ Kyoto univ. Microcomputer Club
# http://mono.kmc.gr.jp/~yhara/
#
require 'sdl'
require 'lib/fpstimer.rb'
require 'lib/input.rb'

# Key definition
class Input
  define_key SDL::Key::ESCAPE, :exit
  define_key SDL::Key::LEFT, :left
  define_key SDL::Key::RIGHT, :right
  define_key SDL::Key::RETURN, :ok
  define_pad_button 0, :ok
end

class Game

  def main
    # Initialization
    SDL.init(SDL::INIT_VIDEO|SDL::INIT_AUDIO|SDL::INIT_JOYSTICK)
    SDL::Mixer.open
    SDL::TTF.init

    # Init screen
    if defined?(SDL::RELEASE_MODE)
      # Invoked via game.exe
      SDL::Mouse.hide
      @screen = SDL.set_video_mode(640, 480, 16, SDL::HWSURFACE|SDL::DOUBLEBUF|SDL::FULLSCREEN)
    else
      # Invoked via debug.exe
      @screen = SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE|SDL::DOUBLEBUF)
    end

    # Create objects
    $score = Score.new

    @input = Input.new
    @font = SDL::TTF.open("image/boxfont2.ttf",40)
    @bgm = SDL::Mixer::Music.load("sound/famipop3.it")
    @player      = Player.new(240, 400-32)
    @items       = Items.new
    @state = :title   # Show title screen first

    # Main loop
    timer = FPSTimerLight.new
    timer.reset
    loop do  
      @input.poll             # Check input
      break if @input[:exit]  #   Exit if ESCAPE is pressed

      act                     # Move objects
      render                  # Render objects
      timer.wait_frame{ @screen.flip } # Wait
    end

    # Finalize
    $score.save
  end

  def act
    case @state
    when :title
      act_title
    when :readygo
      act_readygo
    when :playing
      act_playing
    when :gameover
      act_gameover
    end
  end

  # Title screen (press ENTER -> READY GO)
  def act_title
    @player.act(@input)
    if @input.ok
      @state = :readygo
      @time = 0
    end
  end

  # READY GO (Start game after a while)
  def act_readygo
    @time += 1

    if @time > 120
      @state = :playing
      SDL::Mixer.play_music(@bgm,-1)
    end
  end

  # Playing the game (GAME OVER if hit bomb)
  def act_playing
    @player.act(@input)
    crash = @items.act(@player)

    if crash 
      @state = :gameover
      SDL::Mixer.halt_music
      @time = 0
    end
  end

  # GAME OVER (Show title after a while)
  def act_gameover
    @time += 1

    if @time > 120
      @state = :title
      @items.reset
      $score.reset
    end
  end

  def render
    # Render background
    @screen.fill_rect(0,0,  640,400, [128,255,255])
    @screen.fill_rect(0,400,640,180, [0,128,0])

    # Render characters
    @player.render(@screen)
    @items.render(@screen)

    # Render score
    @font.drawBlendedUTF8(@screen, "SCORE %05d  HIGH %05d" % [$score.score,$score.highscore], 0,0, 0,0,0) 

    # Render messages
    case @state
    when :title
      @font.drawBlendedUTF8(@screen,"THE APPLE CATCHER",0,210, 255,0,0)
      @font.drawBlendedUTF8(@screen,"PUSH ENTER",0,260, 0,0,0)
    when :gameover
      @font.drawBlendedUTF8(@screen,"game over",0,240, 255,0,0)
    when :readygo
      if @time < 60
        @font.drawBlendedUTF8(@screen,"ready",0,240, 255,0,0)
      else
        @font.drawBlendedUTF8(@screen,"go!",0,240, 255,0,0)
      end
    end
  end

end

class Player

  def initialize(x,y)
    @x, @y = x, y
    
    # Load image
    image = SDL::Surface.loadBMP("image/noschar.bmp")
    image.set_color_key(SDL::SRCCOLORKEY|SDL::RLEACCEL, [255,255,255])
    # Extract four images from the top-most row
    @images = []
    4.times do |x|
      @images << image.copy_rect(32*x,0,32,32).display_format
    end

    # Counter for character animation
    @img_ct = 0
  end
  attr_reader :x, :y

  def act(input)
    # Control
    move(-8) if input.left
    move(+8) if input.right
    # Animation
    @img_ct += 1
    @img_ct = 0 if @img_ct >= 40
  end

  def render(screen)
    screen.put(@images[@img_ct/10], @x, @y)
  end

  def move(dist)
    @x += dist
    @x = 640-16 if @x > 640-16
    @x = -16 if @x < -16
  end

end

# Falling items
class Items
  Item = Struct.new(:type,:x,:y,:v)

  def initialize
    # Load image
    @img_apple = SDL::Surface.loadBMP("image/ringo.bmp")
    @img_apple.set_color_key(SDL::SRCCOLORKEY, [255,255,255])
    @img_bomb = SDL::Surface.loadBMP("image/bomb.bmp")
    @img_bomb.set_color_key(SDL::SRCCOLORKEY, [255,255,255])

    # Load sound
    @sound_get  = SDL::Mixer::Wave.load("sound/get.wav")
    @sound_bomb = SDL::Mixer::Wave.load("sound/bom08.wav")

    reset
  end

  def reset
    @items = []
  end

  # Collision detection of apples
  def hit_apple?(apple, player)
    xdiff = (apple.x+38) - (player.x+16)
    ydiff = (apple.y+48) - (player.y+16)
    distance = Math.sqrt(xdiff**2 + ydiff**2)

    distance < (40+16)
  end

  # Collision detection of bombs
  def hit_bomb?(bomb, player)
    xdiff = (bomb.x+36) - (player.x+16)
    ydiff = (bomb.y+54) - (player.y+16)
    distance = Math.sqrt(xdiff**2 + ydiff**2)

    distance < (34+8)
  end

  def act(player)
    crash = false

    # Move
    @items.each do |item|
      item.y += item.v
      #item.x += item.v-8    # <- secret mode :-)
    end
      
    # Collision detection
    @items.each do |item|
      case item.type
      when :apple
        if hit_apple?(item, player)
          SDL::Mixer.play_channel(-1,@sound_get,0) 
          item.y += 480
          $score.add(10)
        end
      when :bomb
        if hit_bomb?(item, player)
          SDL::Mixer.play_channel(-1,@sound_bomb,0) 
          crash = true
        end
      end
    end

    # Remove items gone out of screen
    @items.delete_if do |item|
      item.y > 480
    end

    # Generate new items
    while @items.size < 5
      newx = rand(640) 
      type = (rand(100) < 80) ? :bomb : :apple
      @items << Item.new(type, newx, 0, rand(9)+4)
    end

    # Return if hit bomb
    crash
  end

  def render(screen)
    # Render each item
    @items.each do |item|
      case item.type
      when :apple
        screen.put(@img_apple, item.x, item.y)
      when :bomb
        screen.put(@img_bomb, item.x,item.y)
      end
    end
  end
end

class Score
  SCOREFILE = "score.dat"

  def initialize
    # Load highscore form file (if any)
    if File.exist?(SCOREFILE)
      @highscore = File.open(SCOREFILE,"rb"){|f| Marshal.load(f)}
    else
      @highscore = 0
    end
    @score = 0
  end
  attr_reader :score, :highscore

  # Reset score and update highscore
  def reset
    if @highscore < @score
      @highscore = @score
    end
    @score = 0
  end
  
  # Save highscore
  def save
    data = @highscore
    File.open(SCOREFILE,"wb"){|f| Marshal.dump(data,f)}
  end

  def add(value)
    @score += value
  end
end

# Start this program
Game.new.main

