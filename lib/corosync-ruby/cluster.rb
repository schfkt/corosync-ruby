module Corosync
  class Cluster
    COMMAND = "sudo crm"

    def initialize
      parse
    end

    def healthy
      if @online.size < @nodes_configured
        false
      elsif @resources_started.size < @resources_configured
        false
      elsif @failed_actions.size != 0
        false
      else
        true
      end  
    end

    def health_description
      description = ""
      ok = healthy
      
      if ok
        description += "OK"
      else
        description += "ERROR"
      end
      description += ", #{@nodes_configured} nodes configured"
      if @online.size != 0
        description += ", #{@online.size} nodes online #{@online.inspect}"
      end
      if !ok && @offline.size != 0
        description += ", #{@offline.size} nodes offline #{@offline.inspect}"
      end   
      description += ", #{@resources_configured} resources configured"
      if @resources_started.size != 0
        description += ", #{@resources_started.size} resources started #{@resources_started.inspect}"
      end
      if !ok && @resources_stopped.size != 0
        description += ", #{@resources_stopped.size} resources stopped #{@resources_stopped.inspect}"
      end
      if !ok && @failed_actions.size != 0
        description += ", Failed actions #{@failed_actions.inspect}"
      end
      description.gsub("\"", "")
    end

    def current_node_active?
      current_node = `hostname`.strip
      @online.include?(current_node)
    end

    private

    def parse
      # get status info
      cmd = COMMAND + " status"
      output = `#{cmd}`

      # parse output
      @nodes_configured = []
      if /(\d+) Nodes configured/.match(output)
        @nodes_configured = Regexp.last_match[1].to_i 
      else
        raise "Can't parse output"
      end

      @resources_configured = []
      if /(\d+) Resources configured/.match(output)
        @resources_configured = Regexp.last_match[1].to_i
      else
        raise "Can't parse output"
      end

      @online = []
      if /Online: \[ ([\w ]*) \]/.match(output)
        @online = Regexp.last_match[1].split(' ')  
      end

      @offline = []
      if /OFFLINE: \[ ([\w ]*) \]/.match(output)
        @offline = Regexp.last_match[1].split(' ')  
      end

      raise "Can't parse output" if @online.empty? && @offline.empty?

      @resources_started = []
      @resources_stopped = []
      resources = output.scan(/^\s*(\w+)\s*\([\w:]+\):\s*([\w ]*)$/)
      resources.each do |res|
        status = res[1].split(' ')
        if status.include? 'Started'
          @resources_started << res[0]
        else
          @resources_stopped << res[0]
        end
      end

      raise "Can't parse output" if @resources_started.empty? && @resources_stopped.empty?

      @failed_actions = []
      if (/Failed actions:.*/m).match(output)
        failed = Regexp.last_match[0].scan(/^\s+.*$/)
        @failed_actions = failed.map { |e| e.lstrip }
      end
    end
  end
end
