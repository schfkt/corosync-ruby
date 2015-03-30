module Corosync
  class Resource
    COMMAND = "sudo crm resource"
    
    attr_reader :status, :started_on, :started_locally

    def initialize(name)
      @name = name
      parse
    end

    private

    def parse
      # get status info
      cmd = COMMAND + " status #{@name}"
      output = `#{cmd}`

      # parse it
      if output.include? "NOT running"
        @status = "stopped"
      elsif /is running on: (\w*)/.match(output)
        @status = "started"
        @started_on = Regexp.last_match[1]

        # get hostname of the current machine
        current_hostname = `hostname`.strip
        @started_locally = @started_on == current_hostname 
      else
        raise "Can't parse output"
      end
    end  
  end
end
