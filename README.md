What is Tunnel?
===============

Tunnel allows you run ruby code inside Sketchup directly from your IDE.  Though the [SketchUp Bridge](http://www.ibm.com/developerworks/opensource/library/os-eclipse-sketchup1/) does too allow you to do this, the Tunnel captures output and displays it in your IDE console.

How do I use it?
================

Requirements:  Ruby must be installed on the system (and SketchUp, obviously)

1) copy tunnel_skp.rb to your SketchUp plugins directory.
2) copy tunnel_ide.rb somewhere your IDE can find it
3) You'll have to configure the IDE to issue the appropriate system command.  If you get a configuration to work, email me and I'll add it here.

- sublime text

				{
					"cmd": ["ruby", <<path to tunnel_ide.rb>>, "$file"],
					"file_regex": "^(...*?):([0-9]*):?([0-9]*)"
				}


How does it work?
=================

It's a hack.  But it has proved the most effective hack I've ever put together.  When SketchUp runs it loads the plugin and starts a timer that is called every x milliseconds.  When the timer is called, it uses an undocumented class called SUSocket to connect to port 1517.  Usually the connection is refused and everything continues as usual.

Upon building in your IDE, ruby runs tunnel_ide.rb which starts up a socket listening on port 1517 and waits for SketchUp to connect.  The IDE tells the SketchUp tunnel what files to load and then waits for SketchUp to respond.