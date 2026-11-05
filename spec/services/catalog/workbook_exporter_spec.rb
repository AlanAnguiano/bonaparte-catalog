# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::WorkbookExporter do
  let(:input_path) { Dir[Rails.root.join("data/data_prueba*.xlsx")].min }
  let(:result) do
    products = Catalog::WorkbookImporter.call(input_path)
    evidence = Catalog::EvidenceRepository.load(Rails.root.join("evidence"))
    Catalog::CatalogResolver.call(products:, evidence_repository: evidence)
  end

  it "writes the six required sheets with contract headers" do
    Dir.mktmpdir do |dir|
      output = File.join(dir, "out.xlsx")
      described_class.call(result:, output_path: output)

      book = Roo::Excelx.new(output)
      expect(book.sheets).to eq(%w[Origen Métricas Aplicaciones Intercambios Atributos Catálogo])
      expect(book.sheet("Origen").row(1)).to eq(Catalog::WorkbookImporter::ORIGEN_HEADERS)
      expect(book.sheet("Aplicaciones").row(1)).to eq(described_class::APPLICATION_HEADERS)
      expect(book.sheet("Intercambios").row(1)).to eq(described_class::INTERCHANGE_HEADERS)
      expect(book.sheet("Atributos").row(1)).to eq(described_class::ATTRIBUTE_HEADERS)
      expect(book.sheet("Catálogo").row(1)).to eq(described_class::CATALOG_HEADERS)
    end
  end

  it "derives metrics from exported row counts" do
    Dir.mktmpdir do |dir|
      output = File.join(dir, "out.xlsx")
      described_class.call(result:, output_path: output)

      metrics = Roo::Excelx.new(output).sheet("Métricas")
      expect(metrics.row(2)).to eq([ "Referencias:", result.origen.size ])
      expect(metrics.cell(4, 2)).to eq(result.applications.size)
      expect(metrics.cell(8, 2)).to eq(result.interchanges.size)
      expect(metrics.cell(12, 2)).to eq(result.attributes.size)
    end
  end
end
