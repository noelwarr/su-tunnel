require 'sketchup'

# I guess this could be a class but because SKSocket can only handle
# one connection at a time I feel more comfortable with it being
# a module.  When started, the Tunnel tries to connect to port 1517.
# If successful, it then loads whatever the connection tells it to,
# logs the output and feeds it back through the socket
module SketchUpTunnel

  HOST            = '127.0.0.1'.freeze
  PORT            = 1517

  @attached       = false
  @connected      = false
  @running_script = false
  @log            = Array.new

  def self.connected?;      @connected;      end;
  def self.running_script?; @running_script; end;
  def self.log;             @log;            end;

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

  def self.connect
    if !@connected
      @connected = true
      SKSocket.connect(HOST, PORT)
      SKSocket.add_socket_listener { |msg|
        if msg[0..4] == 'LOAD:'
          begin
            path = msg[5..-1]
            @running_script = true
            load path
            @running_script = false
            SKSocket.write(self.log.join)
            SKETCHUP_CONSOLE(self.log.join)
          rescue Exception => e
            @running_script = false
            SKSocket.write(
              self.log.join <<
              e.message <<
              "\n" <<
              e.backtrace[0..-3].join("\n")
            )
            SKETCHUP_CONSOLE(
              self.log.join <<
              e.message <<
              "\n" <<
              e.backtrace[0..-3].join("\n")
            )
          end
          self.log.clear
        end
        if msg != 'Connection established'
          SKSocket.disconnect
          @connected = false
        end
      }
    end
  end

  def self.start
    @timer = UI.start_timer(1.4, true) {
      self.connect
    }
    self
  end

  def self.stop
    UI.stop_timer(@timer)
    @timer = true
    self
  end

  def self.attach
    proxy = TunnelProxy.new
    $stdout = proxy
    $stderr = proxy
    @attached = true
    self.start
    Sketchup.write_default('SU_Tunnel', 'Attached', true)
    nil
  end

  def self.detach
    self.stop
    $stdout = SKETCHUP_CONSOLE
    $stderr = SKETCHUP_CONSOLE
    @attached = false
    Sketchup.write_default('SU_Tunnel', 'Attached', false)
    nil
  end

  class TunnelProxy

    def write(*args)
      if SketchUpTunnel.running_script?
        length = 0
        for arg in args
          input = arg.to_s
          SketchUpTunnel.log << input
          length += input.length
        end
        length
      else
        0
      end
    end

    # This is called some times by Ruby 2.0.
    def flush
      SketchUpTunnel.connect
      self
    end

    # Indicate that the content is buffered.
    def sync
      false
    end

    def sync=(value)
      raise NotImplementedError
    end

  end # class

end # module

# Attach tunnel if it was loaded last session.
unless file_loaded?(__FILE__)
  if Sketchup.read_default('SU_Tunnel', 'Attached', false)
    SketchUpTunnel.attach
  end
end

file_loaded(__FILE__)
