require "XcodePages/version"

module XcodePages
  # Prints the environment. Xcode passes many useful pieces of information via
  # the Unix environment.
  #
  # This can be useful for testing. Add an external build target to Xcode. Make
  # the Build Tool equal to /bin/sh and make the arguments equal to:
  #
  #   -c "$HOME/.rvm/bin/rvm-auto-ruby -r XcodePages -e XcodePages.print_env"
  #
  # and you will see all the Unix environment variables. This assumes that you
  # are using RVM in your local account to manage Ruby.
  def self.print_env
    ENV.each { |key, value| puts "#{key}=#{value}" }
  end

  # Searches for all the available source files in the current working directory
  # or below. Pulls out their directory names and answers an array of unique
  # space-delimited relative folder paths. These directory names will become
  # Doxygen input folders.
  #
  # The implementation assumes that the current working directory equals the
  # Xcode source root. It also makes some simplifying assumptions about spaces
  # in the paths: that there are *no* spaces. Doxygen uses spaces to delimit the
  # files and directories listed for input. But what if the paths themselves
  # contain spaces?
  def self.input
    Dir.glob('**/*.{h,m,mm}').map { |relative_path| File.dirname(relative_path) }.uniq.join(' ')
  end
end
