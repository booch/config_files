# Add completion to IRB console. Makes it easier to see what methods are available on an object or class.
require 'irb/completion'

# Force use of Readline library, so we get better command-line editing.
ARGV.concat [ "--readline"]


# Automatically indent.
IRB.conf[:AUTO_INDENT] = true

# Set the IRB console prompt.
#IRB.conf[:PROMPT_MODE] = :SIMPLE

# The 'pp' extension is nice for pretty-printing output.
require 'pp'

# The below come as gems, so we have to load RubyGems.
require 'rubygems'

# The 'ap' extension is even nicer for pretty-printing output. Requires config to be in ~/.aprc though. See http://github.com/michaeldv/awesome_print for details.
begin
  require 'ap'
  AwesomePrint.defaults = {
    :sorted_hash_keys => true
  }

  # Use AwesomePrint in place of PrettyPrint.
  alias pp ap

  # Make IRB output use AwesomePrint automagically. From http://stackoverflow.com/questions/123494/whats-your-favourite-irb-trick/3091252#3091252
  if IRB.version.include?('DietRB') # MacRuby
    IRB.formatter = Class.new(IRB::Formatter) do
      def inspect_object(object)
        object.ai
      end
    end.new
  else # regular IRB
    IRB::Irb.class_eval do
      def output_value
        ap @context.last_value
      end
    end
  end
rescue LoadError => err
  warn "Couldn't load AwesomePrint: #{err}"
end

# Enable Wirble: colorize IRB output; save history across sessions in ~/.irb_history file.
# Automatically loads rubygems, pp, and irb/completion.
# Adds a fewe aliases: ri (run ri docs), po (print object methods), poc (print object constants).
# See http://pablotron.org/software/wirble/ for details.
begin
  require 'wirble'
  Wirble.init :init_colors => true, :colors => {:number => :nothing}
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


# Use Pry if we can.
begin
  require 'pry'
  Pry.start || exit
rescue LoadError
  warn "Couldn't load Pry: #{err}"
end


# Enable project-specific .irbrc files. From http://greatseth.wordpress.com/2010/02/11/project-specific-irbrc/.
if Dir.pwd != File.expand_path("~")
  local_irbrc = File.expand_path '.irbrc'
  if File.exist? local_irbrc
    puts "Loading #{local_irbrc}"
    load local_irbrc
  end
end


# Make it easier to get a more useful list of methods.
class Object
  def local_methods
    (methods - Object.instance_methods).sort
  end
end
