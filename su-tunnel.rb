Sketchup = false unless defined?(Sketchup)
if Sketchup
	ARGV = []
else
	SKETCHUP_CONSOLE = $stdout
	UI = Module.new
	UI::Command = Class.new
	def file_loaded?(path); true; end
end

module SketchUpTunnel
	
	TEMP_PATH = File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] )
	IN_PATH = File.join(TEMP_PATH, "skp_tunnel.in")
	OUT_PATH = File.join(TEMP_PATH, "skp_tunnel.out")

	@attached   = false
	@timer 			= nil
	unless file_loaded?(__FILE__)
    cmd = UI::Command.new('Ruby $stdout Tunnel') {
      if @attached
        self.detach
      else
        self.attach
      end
    }
    cmd.set_validation_proc {
      if @attached
        MF_ENABLED | MF_CHECKED
      else
        MF_ENABLED | MF_UNCHECKED
      end
    }
    menu = UI.menu('Plugins')
    menu.add_item(cmd)
  end

	def self.attach
    @attached = true
    Sketchup.write_default('SU_Tunnel', 'Attached', true)
    @timer = UI.start_timer(1.4, true) {
      path = SketchUpTunnel.get_file_to_load
			SketchUpTunnel.load_inside_sketchup(path) unless path.nil?
    }
    nil
  end

  def self.detach
    @attached = false
    Sketchup.write_default('SU_Tunnel', 'Attached', false)
    UI.stop_timer(@timer)
    nil
  end

	def self.set_file_to_load(path)
		File.open(IN_PATH,"w+"){|io| io.write path	} rescue raise("The tunnel appears to be a little clogged up.")
	end

	def self.get_output
		until File.exist?(OUT_PATH) && File.writable?(OUT_PATH)
      sleep 0.1
    end
   	output =  File.open(OUT_PATH).read
   	File.delete(OUT_PATH)
   	output
	end

	def self.get_file_to_load
		if File.exist?(IN_PATH) && File.writable?(IN_PATH)
			path = File.open(IN_PATH).read
			File.delete(IN_PATH)
			return path
		end
	end

	def self.load_inside_sketchup(path)
		prox = TunnelProxy.new
		begin
			load(path)
		rescue Exception => e
			puts e.message
			puts e.backtrace[0..-4].join("\n")
		end
		captured_io = prox.finalize
		raise "Tunnel output path seems to be unwritable: #{OUT_PATH}" if File.exist?(OUT_PATH) && !File.writable?(OUT_PATH)
		File.open(OUT_PATH,"w+"){|io|
			io.write(captured_io)
		}
	end

	def self.load_outside_sketchup(path)
		set_file_to_load(path)
		puts get_output

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


if Sketchup
	# Attach tunnel if it was loaded last session.
	unless file_loaded?(__FILE__)
		if Sketchup.read_default('SU_Tunnel', 'Attached', false)
		  SketchUpTunnel.attach
		end
	end
else
	SketchUpTunnel.load_outside_sketchup(ARGV.first)
end
