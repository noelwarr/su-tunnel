To all frequent users and contributors
======================================
Major changes: I recently switched to OSX and found that the Tunnel wouldn't work because SKSocket behaves differently.  The tunnel now uses files to communicate between SketchUp and IDE.  I have merged the code of tunnel_ide and tunnel_skp into one file that goes in your plugins folder.  Point the IDE to that file.


What is Tunnel?
===============

Tunnel allows you run ruby code inside Sketchup directly from your IDE.  Though the [SketchUp Bridge](http://www.ibm.com/developerworks/opensource/library/os-eclipse-sketchup1/) allows you to do this, the Tunnel captures output and displays it in your IDE console.

How do I use it?
================

Requirements:  Ruby must be installed on the system (and SketchUp, obviously)

1. copy tunnel.rb to your SketchUp plugins directory.
2. configure your IDE.

Sublime Text
============

For sublime, you will have to edit "SketchUp.sublime-build" replacing -path-to-plugins- with the full path to your plugins folder.  Save the file in the sublime user packages directory.  This can be a bit tricky to find on windows.  It should be something like C:\Users\Name\AppData\Roaming\Sublime Text 3\Packages\User.  Try opening a windows file explorer and enter **%appdata%**.  That should take you to a folder you can navigate from.

NetBeans
============
Contributor: [Jernej Vidmar](https://github.com/Nazz78)

For NetBeans, copy tunnel_ide.rb and /NetBeans/sketchup_build.rb to some location which you will add to your NetBeans
project (eg. C:\Users\Name\NetBeansUtils\). Put both files at the same level. Take a look at the sketchup_build.rb and 
modify it to suit your needs (set which files & folder should be checked for changes).
Now open NetBeans, right click on your Project and select "Properties", then select "Run" on the left side.
Set "sketchup_build.rb" as your main file and you are set! When you call Run from NetBeans, this scripts will first
check for the last modified Ruby file and send it directly to SketchUp.

Troubleshooting
===============

If you're having problems communicating through the Tunnel you can narrow down where the problem might be comming from.

1. SketchUp -> Run SketchUp, open a console and type in `SketchUpTunnel` to see if the module has been loaded.
2. Ruby in path -> Open a shell and type
				`ruby -e "puts 'hello world'"`
3. Tunnel -> Navigate to the SketchUp plugins folder and add a test ruby script there.  Something like my_test.rb containing a few `puts()`.  Then at the console try
				`ruby su-tunnel.rb my_test.rb`


How does it work?
=================

It's a hack.  But it has proved the most effective hack I've ever put together.  When SketchUp runs it loads the plugin and starts a timer that is called every x milliseconds.  When the timer is called, it tries to opens a file in a temp directory.  If no file is found it does nothing

Upon building in your IDE, ruby runs su-tunnel.rb which creates a file in the temp directory containg the path of the file we want to run in SketchUp.  SketchUp will find the file load it and append the stdout produced to the end of that file.  Your IDE will then read it display the results in the console
