# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::CatalogResolver do
  let(:products) { Catalog::WorkbookImporter.call(Dir[Rails.root.join("data/data_prueba*.xlsx")].min) }
  let(:evidence) { Catalog::EvidenceRepository.load(Rails.root.join("evidence")) }
  subject(:result) { described_class.call(products:, evidence_repository: evidence) }

  it "only projects export:true facts and expands years for RM-152" do
    rm_apps = result.applications.select { |r| r["Referencia"] == "RM-152" }
    expect(rm_apps).not_to be_empty
    expect(rm_apps.map { |r| r["Año"] }).to all(be_a(Integer))
    expect(rm_apps.map { |r| r["Modelo"] }).to include("Frontier", "240SX")

    rejected_years = rm_apps.select { |r| r["Año"] < 1989 }
    expect(rejected_years).to be_empty
  end

  it "exports interchanges with Aftermarket or OEM only" do
    expect(result.interchanges).not_to be_empty
    expect(result.interchanges.map { |r| r["Origen"] }).to all(be_in(%w[Aftermarket OEM]))
  end

  it "sorts applications deterministically" do
    keys = result.applications.map { |r|
      [ r["Referencia"], r["Fabricante"], r["Modelo"], r["Año"] ]
    }
    expect(keys).to eq(keys.sort)
  end

  it "includes catalog rows for products with evidence" do
    expect(result.catalog.map { |r| r["Referencia"] }).to include("RM-152", "TK1283-1", "SP26-329R/L+20")
  end

  it "keeps TK1283-1 applications empty when evidence has none exported" do
    expect(result.applications.select { |r| r["Referencia"] == "TK1283-1" }).to be_empty
  end
end
