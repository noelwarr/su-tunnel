# I guess this could be a class but because SKSocket can only handle
# one connection at a time I feel more comfortable with it being
# a module.  When started, the Tunnel tries to connect to port 1517.
# If successful, it then loads whatever the connection tells it to,
# logs the output and feeds it back through the socket
module Tunnel

  HOST            = '127.0.0.1'.freeze
  PORT            = 1517

  @connected      = false
  @running_script = false
  @log            = Array.new

  def self.connected?;      @connected;      end;
  def self.running_script?; @running_script; end;
  def self.log;             @log;            end;

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
            SKSocket.write(Tunnel.log.join)
          rescue Exception => e
            @running_script = false
            SKSocket.write(
              Tunnel.log.join <<
              e.message <<
              "\n" <<
              e.backtrace[0..-3].join("\n")
            )
          end
          Tunnel.log.clear
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
      Tunnel.connect
    }
    Tunnel
  end

  def self.stop
    UI.stop_timer(@timer)
    @timer = true
    Tunnel
  end

end


class TunnelProxy

  def write(*args)
    if Tunnel.running_script?
      length = 0
      for arg in args
        input = arg.to_s
        Tunnel.log << input
        length += input.length
      end
      length
    else
      0
    end
  end

  # This is called some times by Ruby 2.0.
  def flush
    Tunnel.connect
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

proxy = TunnelProxy.new
$stdout = proxy
$stderr = proxy

# Perhaps wrap this into a menu option. I allways want it on.
Tunnel.start