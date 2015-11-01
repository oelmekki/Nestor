#!/usr/bin/ruby
require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'socket'
include Socket::Constants

## Launch script: ruby volcano_ftp.rb 4242


# Volcano FTP class
class VolcanoFtp
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
    while (42)
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
      unless Process.waitpid(pid, Process::WNOHANG).nil?
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

  class FtpCommands
    attr_reader :cs

    def initialize( cs )
      @cs = cs
    end

    def syst(args)
      cs.write "215 UNIX Type: L8\r\n"
      0
    end

    def noop(args)
      cs.write "200 Don't worry my lovely client, I'm here ;)"
      0
    end

    def error_502(*args)
      puts "Command not found"
      cs.write "502 Command not implemented\r\n"
      0
    end

    def exit(args)
      cs.write "221 Thank you for using Volcano FTP\r\n"
      -1
    end
  end
end

# Main

if ARGV[0]
  begin
    ftp = VolcanoFtp.new(ARGV[1])
    ftp.run
  rescue SystemExit, Interrupt
    puts "Caught CTRL+C, exiting"
  rescue RuntimeError => e
    puts e
  end
end
