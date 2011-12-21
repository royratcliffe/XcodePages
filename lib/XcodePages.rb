# encoding: utf-8

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

  # Searches for all the available source files (files with h, m or mm
  # extension) in the current working directory or below. Pulls out their
  # directory names and answers an array of unique space-delimited relative
  # folder paths. These directory names will become Doxygen input folders.
  #
  # The implementation assumes that the current working directory equals the
  # Xcode source root. It also makes some simplifying assumptions about spaces
  # in the paths: that there are *no* spaces. Doxygen uses spaces to delimit the
  # files and directories listed for input. But what if the paths themselves
  # contain spaces?
  #
  # Note that this method works correctly when the source root itself contains
  # headers or sources. In this case, the answer will contain the "." directory.
  def self.input
    Dir.glob('**/*.{h,m,mm}').map { |relative_path| File.dirname(relative_path) }.uniq.join(' ')
  end
  
  # Answers the project "marketing version" using Apple's +agvtool+. The
  # marketing version is the "bundle short version string" appearing in the
  # bundle's +Info.plist+. Cocoa only uses this for display in the standard
  # About panel.
  def self.marketing_version
    %x(agvtool mvers -terse1).chomp
  end
  
  # Answers the project build version using Apple's +agvtool+. This is the real
  # version number, equating to +CURRENT_PROJECT_VERSION+.
  def self.build_version
    %x(agvtool vers -terse).chomp
  end
  
  # Answers what Doxygen calls the ‘project number.’ This is the revision
  # number appearing beside the project name in the documentation title. Uses
  # the marketing and build version numbers in the format +vMV (BV)+ where +MV+
  # stands for marketing version and +BV+ stands for build version. Omits the
  # build version if the project matches marketing and build version. No sense
  # repeating the same number if they are the same.
  def self.project_number
    project_number = "v#{marketing_version}"
    project_number << " (#{build_version})" if build_version != marketing_version
  end
end
