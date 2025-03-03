module LinkChecker::UriChecker
  class Danger < Problem
    def initialize(**options)
      super(type: :danger, **options)
    end
  end
end
