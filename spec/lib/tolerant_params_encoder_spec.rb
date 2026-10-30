require "rails_helper"

RSpec.describe LinkChecker::UriChecker::TolerantParamsEncoder do
  describe "parity with the default encoder for valid input" do
    [
      { "q" => "caf\u00e9" },
      { "b" => "2", "a" => "1" },
      { "arr" => %w[1 2] },
      { "h" => { "k" => "v v" } },
      { "sp" => "a b+c" },
    ].each do |params|
      it "encodes #{params.inspect} identically to Faraday::NestedParamsEncoder" do
        expect(described_class.encode(params))
          .to eq(Faraday::NestedParamsEncoder.encode(params))
      end
    end

    it "decodes indentically to Faraday::NestedParamsEncoder" do
      query = "a=1&two+words"
      expect(described_class.decode(query))
        .to eq(Faraday::NestedParamsEncoder.decode(query))
    end
  end

  describe "values the default encoder cannot handle" do
    let(:value) { "caf\xE9".dup.force_encoding(Encoding::UTF_8) }

    it "percent-encodes values containing invalid UTF-8 bytes" do
      expect(described_class.encode({ "q" => value })).to eq("q=caf%E9")
    end

    it "round-trips a percent-encoded byte through decode and back" do
      query = "q=caf%E9"
      expect(described_class.encode(described_class.decode(query))).to eq(query)
    end

    it "raises for the default encoder, which is why this custom one exists" do
      expect { Faraday::NestedParamsEncoder.encode({ "q" => value }) }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end
  end
end
