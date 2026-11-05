# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::WorkbookImporter do
  let(:input_path) { Dir[Rails.root.join("data/data_prueba*.xlsx")].min }

  it "imports five source products with integer internal codes" do
    products = described_class.call(input_path)

    expect(products.size).to eq(5)
    expect(products.map(&:part_number)).to include("RM-152", "FSX-5840301", "SP26-329R/L+20")
    expect(products.map(&:internal_code)).to all(match(/\A\d+\z/))
    expect(products.map(&:internal_code)).not_to include(match(/\.0/))
  end

  it "raises when Origen headers are missing" do
    Tempfile.create([ "bad", ".xlsx" ]) do |tmp|
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Origen") do |sheet|
        sheet.add_row(%w[Foo Bar])
        sheet.add_row(%w[1 2])
      end
      package.serialize(tmp.path)

      expect {
        described_class.call(tmp.path)
      }.to raise_error(Catalog::InvalidWorkbookError, /missing headers/i)
    end
  end
end
