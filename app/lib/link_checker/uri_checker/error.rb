module LinkChecker::UriChecker
  class Error < Problem
    def initialize(**options)
      super(type: :error, **options)
    end
  end
end
