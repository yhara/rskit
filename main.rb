#
# RSKit Sample Game - "THE APPLE CATCHER"
# (c)2006, yhara @ Kyoto univ. Microcomputer Club
# http://mono.kmc.gr.jp/~yhara/
#
require 'sdl'
require 'lib/fpstimer.rb'
require 'lib/input.rb'

#キー定義
class Input
  define_key SDL::Key::ESCAPE, :exit
  define_key SDL::Key::LEFT, :left
  define_key SDL::Key::RIGHT, :right
  define_key SDL::Key::RETURN, :ok
  define_pad_button 0, :ok
end

class Game

  def main
    # 初期化
    SDL.init(SDL::INIT_VIDEO|SDL::INIT_AUDIO|SDL::INIT_JOYSTICK)
    SDL::Mixer.open
    SDL::TTF.init

    # 画面の初期化
    if defined?(SDL::RELEASE_MODE)
      # game.exeから起動したとき
      SDL::Mouse.hide
      @screen = SDL.set_video_mode(640, 480, 16, SDL::HWSURFACE|SDL::DOUBLEBUF|SDL::FULLSCREEN)
    else
      # debug.exeから起動したとき
      @screen = SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE|SDL::DOUBLEBUF)
    end

    # オブジェクトの生成
    $score = Score.new

    @input = Input.new
    @font = SDL::TTF.open("image/boxfont2.ttf",40)
    @bgm = SDL::Mixer::Music.load("sound/famipop3.it")
    @player      = Player.new(240, 400-32)
    @items       = Items.new
    @state = :title   #最初はタイトルから

    # メインループ
    timer = FPSTimerLight.new
    timer.reset
    loop do  
      @input.poll             #入力
      break if @input[:exit]  #  ESCAPE押されたら終了

      act                     #動作
      render                  #描画
      timer.wait_frame{ @screen.flip } #待つ
    end

    #終了
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

  # タイトル (ENTERが押されたらREADY GOに)
  def act_title
    @player.act(@input)
    if @input.ok
      @state = :readygo
      @time = 0
    end
  end

  # READY GO (一定時間経ったらゲーム開始)
  def act_readygo
    @time += 1

    if @time > 120
      @state = :playing
      SDL::Mixer.play_music(@bgm,-1)
    end
  end

  # ゲーム中 (爆弾に当たったらGAME OVERに)
  def act_playing
    @player.act(@input)
    crash = @items.act(@player)

    if crash 
      @state = :gameover
      SDL::Mixer.halt_music
      @time = 0
    end
  end

  # GAME OVER (一定時間経ったらタイトルに)
  def act_gameover
    @time += 1

    if @time > 120
      @state = :title
      @items.reset
      $score.reset
    end
  end

  def render
    #背景の描画
    @screen.fill_rect(0,0,  640,400, [128,255,255])
    @screen.fill_rect(0,400,640,180, [0,128,0])

    #キャラクターの描画
    @player.render(@screen)
    @items.render(@screen)

    #スコアの描画
    @font.drawBlendedUTF8(@screen, "SCORE %05d  HIGH %05d" % [$score.score,$score.highscore], 0,0, 0,0,0) 

    #メッセージの描画
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
    
    #画像の読み込み
    image = SDL::Surface.load("image/noschar.png")
    image.set_color_key(SDL::SRCCOLORKEY|SDL::RLEACCEL, [255,255,255])
    #一番上の4マスを切りだして配列に入れる
    @images = []
    4.times do |x|
      @images << image.copy_rect(32*x,0,32,32).display_format
    end

    #アニメーション用のカウンタ
    @img_ct = 0
  end
  attr_reader :x, :y

  def act(input)
    #移動
    move(-8) if input.left
    move(+8) if input.right
    #アニメーション
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

#落下物
class Items
  Item = Struct.new(:type,:x,:y,:v)

  def initialize
    #画像のロード
    @img_apple = SDL::Surface.loadBMP("image/ringo.bmp")
    @img_apple.set_color_key(SDL::SRCCOLORKEY, [255,255,255])
    @img_bomb = SDL::Surface.loadBMP("image/bomb.bmp")
    @img_bomb.set_color_key(SDL::SRCCOLORKEY, [255,255,255])

    #音声のロード
    @sound_get  = SDL::Mixer::Wave.load("sound/get.wav")
    @sound_bomb = SDL::Mixer::Wave.load("sound/bom08.wav")

    reset
  end

  def reset
    @items = []
  end

  #リンゴの当たり判定
  def hit_apple?(apple, player)
    xdiff = (apple.x+38) - (player.x+16)
    ydiff = (apple.y+48) - (player.y+16)
    distance = Math.sqrt(xdiff**2 + ydiff**2)

    distance < (40+16)
  end

  #爆弾の当たり判定
  def hit_bomb?(bomb, player)
    xdiff = (bomb.x+36) - (player.x+16)
    ydiff = (bomb.y+54) - (player.y+16)
    distance = Math.sqrt(xdiff**2 + ydiff**2)

    distance < (34+8)
  end

  def act(player)
    crash = false

    #移動
    @items.each do |item|
      item.y += item.v
      #item.x += item.v-8    #←隠しモード
    end
      
    #当たり判定
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

    #消去
    @items.delete_if do |item|
      item.y > 480
    end

    #生成
    while @items.size < 5
      newx = rand(640) 
      type = (rand(100) < 80) ? :bomb : :apple
      @items << Item.new(type, newx, 0, rand(9)+4)
    end

    #爆弾に当たったかどうかを返す
    crash
  end

  def render(screen)
    #アイテムを一個ずつ描画する
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
    #ハイスコアのロード(ファイルがあれば)
    if File.exist?(SCOREFILE)
      @highscore = File.open(SCOREFILE,"rb"){|f| Marshal.load(f)}
    else
      @highscore = 0
    end
    @score = 0
  end
  attr_reader :score, :highscore

  #スコアのリセット(と、ハイスコアの更新)
  def reset
    if @highscore < @score
      @highscore = @score
    end
    @score = 0
  end
  
  #ハイスコアのセーブ
  def save
    data = @highscore
    File.open(SCOREFILE,"wb"){|f| Marshal.dump(data,f)}
  end

  def add(value)
    @score += value
  end
end

#実行！
Game.new.main

