# Add completion to IRB console. Makes it easier to see what methods are available on an object or class.
require 'irb/completion'

# Force use of Readline library, so we get better command-line editing.
ARGV.concat [ "--readline"]

# Set the IRB console prompt.
#IRB.conf[:PROMPT_MODE] = :SIMPLE

# The 'pp' extension is nice for pretty-printing output.
require 'pp'

# The below come as gems, so we have to load RubyGems.
require 'rubygems'

# Enable Wirble, to colorize IRB output, retain history, and add some other nice features.
# See http://pablotron.org/software/wirble/ for details.
begin
  require 'wirble'
  Wirble.init :init_color => true, :colors => {:number => :nothing}
  Wirble.colorize
rescue LoadError => err
  warn "Couldn't load Wirble: #{err}"
end

# Enable Hirb, so we get automatic table views for ActiveRecord objects.
# See http://github.com/cldwalker/hirb/tree/master for details.
# NOTE: Enable Hirb after Wirble.
begin
  require 'hirb'
  extend Hirb::Console # Add table and view commands to IRB console.
  Hirb::View.enable do |c|
    # Specify fields (and other options) to display for various classes.
    c.output = {'Tag'=>{:options=>{:fields=>%w{id name tag_list}} }}
  end
rescue LoadError => err
  warn "Couldn't load Hirb: #{err}"
end