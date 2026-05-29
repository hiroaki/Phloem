require "rails_helper"

RSpec.describe Phloem::CorsOrigins do
  describe ".parse" do
    it "returns an empty array when the variable is unset" do
      expect(described_class.parse(nil)).to eq([])
    end

    it "splits comma-separated origins and strips whitespace" do
      expect(described_class.parse("https://maps.example.com, https://admin.example.com ,"))
        .to eq(["https://maps.example.com", "https://admin.example.com"])
    end
  end
end