require 'socket'

module VolcanoFtp
  # Volcano FTP class
  class Base
    include Socket::Constants
    # Volcano FTP contants
    BINARY_MODE = 0
    ASCII_MODE = 1
    MIN_PORT = 1025
    MAX_PORT = 65534

    attr_reader :socket, :pids, :commands

    def initialize(port)
      # Prepare instance
      @socket = TCPServer.new("127.0.0.1", port)
      socket.listen(42)

      @pids = []
      puts "Server ready to listen for clients on port #{port}"
    end

    def run
      loop do
        select_result = IO.select([socket], nil, nil, 0.1)
        if got_selection? select_result
          accept_connection!
        else
          purge_processes!
        end
      end
    end

    private

    def got_selection?( select )
      select and select[0].include?(socket)
    end

    def purge_processes!
      pids.each do |pid|
        if Process.waitpid(pid, Process::WNOHANG)
          ####
          # Do stuff with newly terminated processes here

          ####
          pids.delete(pid)
        end
      end
      p pids
    end

    def accept_connection!
      cs, _ = socket.accept
      @commands = FtpCommands.new cs
      pids << Kernel.fork do
        puts "[#{Process.pid}] Instanciating connection from #{cs.peeraddr[2]}:#{cs.peeraddr[1]}"
        cs.write "220-\r\n\r\n Welcome to Volcano FTP server !\r\n\r\n220 Connected\r\n"
        until (line = cs.gets).nil?
          puts "[#{Process.pid}] Client sent : --#{line}--"
          ####
          # Handle commands here
          ####
        end
        puts "[#{Process.pid}] Killing connection from #{peeraddr[2]}:#{peeraddr[1]}"
        cs.close
        Kernel.exit!
      end
    end
  end
end
