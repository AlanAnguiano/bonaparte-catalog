# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::EvidenceRepository do
  subject(:repo) { described_class.load(Rails.root.join("evidence")) }

  it "loads the five challenge evidence files" do
    expect(repo.size).to eq(5)
  end

  it "finds RM-152 / REXITE" do
    evidence = repo.find(part_number: "RM-152", manufacturer: "REXITE")
    expect(evidence).to be_a(Hash)
    expect(evidence.dig("catalog", "product")).to eq("BOMBA DE ACEITE DEL MOTOR")
  end

  it "is case-insensitive on lookup" do
    evidence = repo.find(part_number: "rm-152", manufacturer: "rexite")
    expect(evidence).to be_present
  end

  it "returns nil for unknown products" do
    expect(repo.find(part_number: "NO-SUCH", manufacturer: "ACME")).to be_nil
  end

  it "raises when the evidence directory is missing" do
    expect {
      described_class.load(Rails.root.join("tmp/missing-evidence-dir"))
    }.to raise_error(Catalog::Error, /Evidence directory not found/)
  end
end
