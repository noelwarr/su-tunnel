module SketchUpTunnel
	
  def self.module_loaded?
  	SketchUpTunnel.const_defined?(:MODULE_LOADED)
  end

  def self.module_loaded!
	  unless module_loaded?
	  	SketchUpTunnel.const_set(:MODULE_LOADED, true)
	  end
  end

  def self.reload()
  	load(__FILE__)
  end

	#Now lets declare some stuff to emmulate a bit of sketchup in standard ruby and
	#viceversa

	#Declare what file we're gonna be using to communicate
	unless module_loaded?
		TEMP_DIR 							= File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] )
		SKETCHUP_RUBY =  defined?(Sketchup)
		STANDARD_RUBY = !defined?(Sketchup)
		PATH 									= File.join(TEMP_DIR, "su-tunnel.io")
		BROKEN_TUNNEL_MESSAGE =	"Broken tunnel!"
		IDE_HEADER						= "SOURCE\n"
		SKP_HEADER						= "OUTPUT\n"
	end

	#SKETCHUP_RUBY
	@attached   = false
	@timer 			= nil

	#SKETCHUP_RUBY
	def self.load_sketchup_ui()
		unless module_loaded?
	    cmd = UI::Command.new('Ruby $stdout Tunnel') { @attached ? self.detach : self.attach }
	    cmd.set_validation_proc { @attached ? (MF_ENABLED|MF_CHECKED) : (MF_ENABLED|MF_UNCHECKED) }
	    menu = UI.menu('Plugins')
	    menu.add_item(cmd)
			SketchUpTunnel.attach if Sketchup.read_default('SU_Tunnel', 'Attached', false)
		end
  end

	#SKETCHUP_RUBY
	def self.attach
    @attached = true
    Sketchup.write_default('SU_Tunnel', 'Attached', true)
    File.delete(PATH) if File.exist?(PATH)
    @timer = UI.start_timer(1.4, true) {
      path = SketchUpTunnel.get_source
      unless path.nil?
				captured_io = SketchUpTunnel.sketchup_load(path)
				SketchUpTunnel.sketchup_respond(captured_io)
			end
    }
    nil
  end

  #SKETCHUP_RUBY
  def self.detach
    @attached = false
    Sketchup.write_default('SU_Tunnel', 'Attached', false)
    UI.stop_timer(@timer)
    nil
  end

  #STANDARD_RUBY
	def self.set_file_to_load(path)
			File.open(PATH,"w"){|io| 
				io.write("SOURCE\n")
				io.write("#{path}\n")
			}
	end

	#SKETCHUP_RUBY
	def self.get_source
		if File.exist?(PATH)
			path = File.open(PATH, "r+"){|io|
				return nil if io.eof?
				return nil unless io.readline == IDE_HEADER
				return io.read.chomp
			}
		else
			return nil
		end
	end

	#STANDARD_RUBY
	def self.get_output
		output = nil
		begin
			raise BROKEN_TUNNEL_MESSAGE unless File.exist?(PATH)
			File.open(PATH, "r+"){|io|
					raise BROKEN_TUNNEL_MESSAGE if io.readline != IDE_HEADER
					raise "Looks like no file was specified to be loaded in Sketchup" if io.eof?
					io.readline
					if io.eof?
						sleep 0.1
					else
						raise BROKEN_TUNNEL_MESSAGE if io.readline != SKP_HEADER
						output = io.read
					end
			}
		end until not output.nil?
   	File.delete(PATH)
   	output
	end


	#SKETCHUP_RUBY
	def self.sketchup_load(path)
		prox = TunnelProxy.new
		begin
			dirname = File.dirname(path)
			extname = File.extname(path)
			if extname == ".rb"
				load_path = $LOAD_PATH.clone
				$LOAD_PATH.push(dirname) unless $LOAD_PATH.include?(dirname)
				load(path)
			elsif extname == ".py" && defined?(VRayForSketchUp::Python)
				puts VRayForSketchUp::Python.load_source(path)
			else
				raise "invalid extension #{extname} for #{path}"
			end
		rescue Exception => e
			SKETCHUP_CONSOLE.write("hadnling exception")
			puts e.message
			puts e.traceback if e.respond_to?(:traceback)
			puts e.backtrace
		end
		captured_io = prox.finalize
	end

	#STANDARD_RUBY
	def self.standard_load(path)
		set_file_to_load(path)
		get_output
	end

	def self.sketchup_respond(captured_io)
		if File.exist?(PATH)
			File.open(PATH, "a"){|io|
				io.write(SKP_HEADER)
				io.write(captured_io)
			}
		end
	end

	class TunnelProxy


		attr_reader :log

		def initialize
			$stdout = self
		  $stderr = self
			@log = String.new
		end

		def finalize
			$stdout = SKETCHUP_CONSOLE
		  $stderr = SKETCHUP_CONSOLE
		  @log
		end

    def write(*args)
      length = 0
      args.each{|arg|
        input = arg.to_s
        SKETCHUP_CONSOLE.write(input)
        @log << input
        length += input.length
      }
      length
    end

    # This is called some times by Ruby 2.0.
    def flush
      self
    end

    # Indicate that the content is buffered.
    def sync
      false
    end

    def sync=(value)
      raise NotImplementedError
    end

  end

end

if SketchUpTunnel::SKETCHUP_RUBY
	SketchUpTunnel.load_sketchup_ui unless SketchUpTunnel.module_loaded?
	SketchUpTunnel.module_loaded!
elsif SketchUpTunnel::STANDARD_RUBY
	puts SketchUpTunnel.standard_load(ARGV.first).chomp
end