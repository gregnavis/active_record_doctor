class ActiveSupport::TestCase
  def run
    read_io, write_io = IO.pipe
    read_io.binmode
    write_io.binmode

    if fork
      # Parent: load the result sent from the child

      write_io.close
      result = Marshal.load(read_io)
      read_io.close

      Process.wait
    else
      # Child: just run normally, dump the result, and exit the process to
      # avoid double-reporting.
      result = super

      read_io.close
      Marshal.dump(result, write_io)
      write_io.close
      exit
    end

    result
  end
end
