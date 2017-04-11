module LinkChecker::UriChecker
  class Report
    attr_reader :errors, :warnings

    def initialize(errors: nil, warnings: nil)
      @errors = errors || default_hash(default_hash([]))
      @warnings = warnings || default_hash(default_hash([]))
    end

    def merge(other)
      errors.merge!(other.errors) { |_, oldval, newval| oldval.merge(newval) { |_, oldval2, newval2| oldval2 | newval2 } }
      warnings.merge!(other.warnings) { |_, oldval, newval| oldval.merge(newval) { |_, oldval2, newval2| oldval2 | newval2 } }
      self
    end

    def add_error(key, short_description, long_description)
      errors[key][short_description] << long_description
      self
    end

    def add_warning(key, short_description, long_description)
      warnings[key][short_description] << long_description
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
