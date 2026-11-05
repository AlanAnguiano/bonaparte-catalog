# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::EnrichmentPipeline do
  let(:input_path) { Dir[Rails.root.join("data/data_prueba*.xlsx")].min }
  let(:evidence_dir) { Rails.root.join("evidence") }

  def logical_snapshot(path)
    book = Roo::Excelx.new(path)
    {
      sheets: book.sheets,
      origen: (2..book.sheet("Origen").last_row).map { |i| book.sheet("Origen").row(i) },
      applications: sheet_rows(book, "Aplicaciones"),
      interchanges: sheet_rows(book, "Intercambios"),
      attributes: sheet_rows(book, "Atributos"),
      catalog: sheet_rows(book, "Catálogo"),
      metrics: (1..14).map { |i| book.sheet("Métricas").row(i) }
    }
  end

  def sheet_rows(book, name)
    sheet = book.sheet(name)
    return [] if sheet.last_row.nil? || sheet.last_row < 2

    (2..sheet.last_row).map { |i| sheet.row(i) }
  end

  it "produces the same logical workbook on repeated runs" do
    Dir.mktmpdir do |dir|
      first = File.join(dir, "a.xlsx")
      second = File.join(dir, "b.xlsx")

      described_class.call(input_path:, evidence_dir:, output_path: first)
      described_class.call(input_path:, evidence_dir:, output_path: second)

      expect(logical_snapshot(first)).to eq(logical_snapshot(second))
    end
  end
end
