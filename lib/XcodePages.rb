# encoding: utf-8

require "XcodePages/version"
require 'active_support/core_ext/string'

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

  def self.output_directory
    "#{ENV['PROJECT_NAME']}Pages"
  end

  def self.html_output_directory
    File.join(output_directory, 'html')
  end

  # Launches Doxygen.
  #
  # The implementation derives the Doxygen project name from the environment
  # PROJECT_NAME variable. Xcode passes this variable. Typically, it is a
  # camel-cased name. Using ActiveSupport (part of the Rails framework) the
  # implementation below derives a humanised title; effectively puts spaces
  # in-between the camels!
  def self.doxygen
    IO.popen('doxygen -', 'r+') do |doxygen|
      doxygen.puts <<-EOF
        PROJECT_NAME           = #{ENV['PROJECT_NAME'].titleize}
        PROJECT_NUMBER         = #{project_number}
        OUTPUT_DIRECTORY       = #{output_directory}
        TAB_SIZE               = 4
        EXTENSION_MAPPING      = h=Objective-C
        INPUT                  = #{input}
        SOURCE_BROWSER         = YES
        HTML_TIMESTAMP         = NO
        GENERATE_LATEX         = NO
        HAVE_DOT               = YES
      EOF

      # Let the user override the previous defaults by loading up the Doxyfile
      # if one exists. This should appear in the source root folder.
      if File.exists?('Doxyfile')
        doxygen.write File.read('Doxyfile')
      end

      # Close the write-end of the pipe.
      doxygen.close_write

      # Read the read-end of the pipe and send the lines to standard output.
      puts doxygen.readlines
    end
  end

  def self.doxygen_docset
    doxygen
    # Assume that doxygen succeeds. But what happens when it does not?
    %x(cd #{html_output_directory} ; make)
  end

  def self.doxygen_docset_install
    doxygen
    %x(cd #{html_output_directory} ; make install)
  end
end
