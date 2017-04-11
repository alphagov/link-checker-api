module LinkChecker::UriChecker
  class Report
    attr_reader :errors, :warnings

    def initialize(errors: nil, warnings: nil)
      @errors = errors || default_hash([])
      @warnings = warnings || default_hash([])
    end

    def merge(other)
      errors.merge!(other.errors) { |_, oldval, newval| oldval | newval }
      warnings.merge!(other.warnings) { |_, oldval, newval| oldval | newval }
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

  private

    def default_hash(value)
      Hash.new { |hash, key| hash[key] = value }
    end
  end
end
