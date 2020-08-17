module LinkChecker::UriChecker
  class Warning < Problem
    def initialize(**options)
      super(type: :warning, **options)
    end
  end
end
