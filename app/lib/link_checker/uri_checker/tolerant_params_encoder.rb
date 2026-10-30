module LinkChecker::UriChecker
  module TolerantParamsEncoder
    class << self
      attr_accessor :sort_params, :array_indices, :param_depth_limit
    end

    @sort_params = true
    @array_indices = false
    @param_depth_limit = 100

    extend Faraday::EncodeMethods
    extend Faraday::DecodeMethods

  module_function

    def escape(value)
      str = value.to_s
      utf8 = str.dup.force_encoding(Encoding::UTF_8)
      return Faraday::Utils.escape(str) if utf8.valid_encoding?

      utf8.scrub { |bytes| bytes.bytes.map { |byte| sprintf("%%%02X", byte) }.join }
    end

    def unescape(str)
      Faraday::Utils.unescape(str)
    end
  end
end
