What is Tunnel?
===============

Tunnel allows you run ruby code inside Sketchup directly from your IDE.  Though the [SketchUp Bridge](http://www.ibm.com/developerworks/opensource/library/os-eclipse-sketchup1/) allows you to do this, the Tunnel captures output and displays it in your IDE console.

How do I use it?
================

Requirements:  Ruby must be installed on the system (and SketchUp, obviously)

1. copy tunnel_skp.rb to your SketchUp plugins directory.
2. copy tunnel_ide.rb somewhere your IDE can find it
3. configure your IDE.

Sublime Text
============

For sublime, your best bet is to copy the two relevant files (SketchUp.sublime-build and tunnel_ide.rb) to the sublime 
user packages directory.  This can be a bit tricky to find on windows.  It should be something like 
C:\Users\Name\AppData\Roaming\Sublime Text 3\Packages\User.  Try opening a windows file explorer and enter 
**%appdata%**.  That should take you to a folder you can navigate from.

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
3. Tunnel -> Navigate to the tunnel_ide.rb folder and add a test ruby script there.  Something like my_test.rb containing a few `puts()`.  Then at the console try
				`ruby tunnel_ide.rb my_test.rb`


How does it work?
=================

It's a hack.  But it has proved the most effective hack I've ever put together.  When SketchUp runs it loads the plugin and starts a timer that is called every x milliseconds.  When the timer is called, it uses an undocumented class called SUSocket to connect to port 1517.  Usually the connection is refused and everything continues as usual.

Upon building in your IDE, ruby runs tunnel_ide.rb which starts up a socket listening on port 1517 and waits for SketchUp to connect.  The IDE tells the SketchUp tunnel what files to load and then waits for SketchUp to respond.
