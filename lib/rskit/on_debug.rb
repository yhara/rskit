begin
  if defined?(ExerbRuntime)
    Dir.chdir(File.dirname(ExerbRuntime.filepath))
  end

  $LOAD_PATH.concat [
    "lib/ruby/1.8",
    "lib/ruby/1.8/i386-mswin32",
    "lib/sdl",
  ]

  require "main.rb"

rescue Exception => e
  SDL.quit if defined?(SDL)
  unless e.is_a? SystemExit
    bt = e.backtrace.slice(0..-3)
    puts "#{bt.shift}: #{e.message} (#{e.class})"
    puts bt.map{|s| "\tfrom #{s}"}.join("\n")
    print "(push any key)"
    gets
  end
end

