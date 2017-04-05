module LinkChecker::UriChecker
  class Report
    attr_reader :errors, :warnings

    def initialize(errors: nil, warnings: nil)
      @errors = errors || Hash.new { |hash, key| hash[key] = [] }
      @warnings = warnings || Hash.new { |hash, key| hash[key] = [] }
    end

    def merge(other)
      errors.merge!(other.errors) { |key, oldval, newval| oldval | newval }
      warnings.merge!(other.warnings) { |key, oldval, newval| oldval | newval }
      self
    end

    def add_error(type, text)
      errors[type] << text
      self
    end

    def add_warning(type, text)
      warnings[type] << text
      self
    end

    def has_errors?
      errors.any?
    end
  end
end
