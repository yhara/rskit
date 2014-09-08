if defined?(ExerbRuntime)
  Dir.chdir(File.dirname(ExerbRuntime.filepath))
end

$LOAD_PATH.concat [
  "lib/ruby/1.8",
  "lib/ruby/1.8/i386-mswin32",
  "lib/sdl",
]

module SDL
  RELEASE_MODE = true
end
require 'main.rb'
