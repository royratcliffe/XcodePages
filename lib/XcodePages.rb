# encoding: utf-8

require "XcodePages/version"
require 'active_support/core_ext/string'
require 'tempfile'

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
  #
  # If the current marketing version is symbolic, answers the value of the
  # symbol by looking up the value in the Unix environment. This assumes that
  # Xcode provides the variable; and also assumes that Xcode addresses any
  # nested substitution issues in scenarious where symbols comprise other
  # symbols. Hence if +agvtool+ reports a marketing version equal to
  # +${CURRENT_PROJECT_VERSION}+, the reply equals the value of
  # +CURRENT_PROJECT_VERSION+ found in the environment.
  def self.marketing_version
    mvers = %x(agvtool mvers -terse1).chomp
    mvers =~ /\$\{(\w+)\}/ ? ENV[$1] : mvers
  end

  # Answers the project build version using Apple's +agvtool+. This is the real
  # version number, equating to +CURRENT_PROJECT_VERSION+.
  def self.build_version
    vers = %x(agvtool vers -terse).chomp
    vers =~ /\$\{(\w+)\}/ ? ENV[$1] : vers
  end

  # Answers what Doxygen calls the ‘project number.’ This is the revision
  # number appearing beside the project name in the documentation title. Uses
  # the marketing and build version numbers in the format +vMV (BV)+ where +MV+
  # stands for marketing version and +BV+ stands for build version. Omits the
  # build version if the project matches marketing and build version. No sense
  # repeating the same number if they are the same.
  def self.project_number
    project_number = "v#{marketing_version}"
    project_number << "&nbsp;(#{build_version})" if build_version != marketing_version
    project_number
  end

  # Answers the path of the output directory. Doxygen outputs to this folder.
  # HTML web pages appear in the +html+ sub-folder.
  def self.output_directory
    "#{ENV['PROJECT_NAME']}Pages"
  end

  # Answers the path to the +html+ output sub-folder where Doxygen writes the
  # HTML web pages and the DocSet +Makefile+ when +GENERATE_DOCSET+ equals
  # +YES+.
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

  # Launches Doxygen and builds the Apple DocSet. It does not install the
  # DocSet. The compiled documentation set remains in the +html+ sub-folder.
  def self.doxygen_docset
    doxygen
    # Assume that doxygen succeeds. But what happens when it does not?
    %x(cd #{html_output_directory} ; make)
  end

  # Runs Doxygen and installs the Apple DocSet in the current user's shared
  # documentation folder. Finally, as a courtesy, it tells Xcode about the
  # change; signalling an update in your running Xcode IDE. Documentation
  # updates immediately.
  def self.doxygen_docset_install
    doxygen
    %x(cd #{html_output_directory} ; make install)

    script = Tempfile.open(['XcodePages', '.scpt']) do |script|
      script.puts <<-EOF
        tell application "Xcode"
      EOF
      Dir.glob(File.join(html_output_directory, '*.docset')).each do |docset_path|
        script.puts <<-EOF
        	load documentation set with path "#{ENV['HOME']}/Library/Developer/Shared/Documentation/DocSets/#{File.basename(docset_path)}"
        EOF
      end
      script.puts <<-EOF
        end tell
      EOF
      script.close
      %x(osascript #{script.path})
    end
  end
end
