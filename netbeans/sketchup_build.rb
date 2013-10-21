# This is an extension of Noel Warr's su-tunnel script, which works on NetBeans.
# 
# You need to have tunnel_skp.rb also installed in your Skp/Plugins directory.
# 
# It is a quick and dirty ruby script to load last modified .rb file to SketchUp.
# This script was created as I have not found out a way to send currently
# focused file directly. So what it does it first looks up which is the last
# modified (saved) file and then executes based on Noel's script.
#
# If you know how to pass the file that is focused in NetBeans directly to 
# tunnel script, please let us know!
#
# NetBeans setup:
# Go to your project Properties, under Categories (on left side) select Run.
# Set this script as a Main Script and this should be it.
# You run it by clicking on Run Main Project icon or by pressing F6.

require 'find'

# Here you define where your .rb files reside. You can specify the full path
# if it causes you some problems.
dirs = Dir['../main/', '../tests/']
# Do not include this folders in your search for the last modified date.
excludes = [".hg","ext","env","i18n","license"]
# Check only Ruby files
included_files = ['.rb']

# Set the variable to hold last modified filepath
last_modified_file = String.new
# Go way back in time...
last_modification_time = Time.utc(2000,1,1)
# now search for all the ruby files
for dir in dirs
	folder = ''
	Find.find(dir) do |path|
		if FileTest.directory?(path)
			if excludes.include?(File.basename(path))
				# Don't look any further into this directory.
				Find.prune
			else
				next
			end
		else
			if included_files.include?(File.extname(path))
				# get last modification date of the file...
				file = File.open path, 'r'
				modification_time = file.mtime.utc
				#				puts modification_time
				file.close

				# and set it as last modified if appropriate
				if modification_time > last_modification_time
					last_modified_file = File.expand_path(path)
					last_modification_time = modification_time
				end
			end
		end
	end
end

# Now we go to Noel's script
tunnel_path = File.join(File.dirname(__FILE__), "tunnel_ide.rb")
system("ruby #{tunnel_path} #{last_modified_file}")