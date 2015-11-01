module VolcanoFtp
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
