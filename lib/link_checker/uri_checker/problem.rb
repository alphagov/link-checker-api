module LinkChecker::UriChecker
  class Problem
    attr_reader :type, :message, :suggested_fix, :summary, :priority

    def initialize(type, priority, summary, message, suggested_fix)
      @type = type
      @message = message
      @suggested_fix = suggested_fix
      @summary = summary
      @priority = priority
    end

    def with_priority(increment)
      Problem.new(type, priority + increment, summary, message, suggested_fix)
    end
  end
end
