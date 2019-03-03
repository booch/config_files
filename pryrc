ALIASES = {
  cc: "continue",
  ff: "finish", # Step *out* of current stack frame.
  ii: "step", # Step *into* next method.
  into: "step",
  nn: "next",
  qq: "exit",
  qqq: "exit-all",
  rr: -> { reload! }, # Reload Rails app.
  ss: "show-source",
  xx: "exit-program"
}

AWESOME_PRINT_COLORS = {
  args:       :pale,
  array:      :white,
  bigdecimal: :blue,
  class:      :yellow,
  date:       :greenish,
  falseclass: :red,
  integer:    :blue,
  float:      :blue,
  hash:       :pale,
  keyword:    :cyan,
  method:     :purpleish,
  nilclass:   :red,
  rational:   :blue,
  string:     :yellowish,
  struct:     :pale,
  symbol:     :cyanish,
  time:       :greenish,
  trueclass:  :green,
  variable:   :cyanish
}


## Custom Prompts
if STDIN.tty?
  Pry.config.prompt = [
    proc { |target_self, nesting_level, pry|
      "[#{pry.input_ring.size}] (#{Pry.view_clip(target_self)})#{":#{nesting_level}" unless nesting_level.zero?}> "
    },
    proc { |target_self, nesting_level, pry|
      "[#{pry.input_ring.size}] (#{Pry.view_clip(target_self)})#{":#{nesting_level}" unless nesting_level.zero?}* "
    }
  ]
end


## Non-interactive Sessions
Pry.config.color = false unless STDIN.tty?


## Aliases
ALIASES.each do |abbrev, command|
  if command.is_a?(Proc)
    define_method(abbrev, command)
  else
    Pry.commands.alias_command abbrev.to_s, command.to_s
  end
end


## Hooks

# Show Ruby version on startup
Pry.hooks.add_hook(:before_session, "show_versions") do |output, _binding, _pry|
  unless @pry_versions_shown
    output.puts("Ruby #{RUBY_VERSION}")
    @pry_versions_shown = true
  end
end

# Show current time before executing each command
Pry.hooks.add_hook(:after_read, "show_time") do |_input_string, pry|
  pry.output.puts("\x1b[40m\x1b[1;36m#{Time.now.getlocal.strftime("%Y-%m-%d %H:%M")}\x1b[00m")
end


## AwesomePrint
begin
  require "awesome_print"

  # Force use of `less` as our pager, and allow color.
  ENV["PAGER"] = "less -R"

  # Hook into Pry, so Pry output will automatically use `AwesomePrint.ap`.
  # NOTE: This does what `AwesomePrint.pry!` does, but doesn't override auto-pagination.
  # TODO: See https://github.com/awesome-print/awesome_print/issues/347 if has been fixed.
  Pry.config.print = proc do |_output, value, pry|
    # Don't show Array indexes, and indent 2, so it looks like normal Ruby.
    # TODO: Once https://github.com/awesome-print/awesome_print/issues/209 is fixed:
    #         * We should move this out of the `Pry.config.print` block.
    #         * We can remove the AWESOME_PRINT_COLORS, unless we want to customize them.
    AwesomePrint.defaults = {
      index: false,
      indent: 2,
      color: AWESOME_PRINT_COLORS
    }
    pry.pager.page(value.awesome_inspect)
  end
rescue LoadError
  puts "Can't find awesome_print. :("
end


## Rails
# Load Rails config if we're running Rails console.
load "~/.railsrc" if defined?(Rails) && Rails.env
