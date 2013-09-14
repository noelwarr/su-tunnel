require 'socket'
HOST = "127.0.0.1"
PORT = 1517

def kill_server
	socket = TCPSocket.open(HOST,PORT)
	socket.puts
	socket.close
	sleep 2
end

begin
	server = TCPServer.new(HOST, PORT)
rescue 
	kill_server
	server = TCPServer.new(HOST, PORT)
end
client = server.accept
client.puts "LOAD:" + ARGV[0]
puts client.read
client.close