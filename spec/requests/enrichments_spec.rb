# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enrichments", type: :request do
  let(:input_path) { Dir[Rails.root.join("data/data_prueba*.xlsx")].min }

  it "renders the upload form" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Descargar")
    expect(response.body).to include("bin/rails catalog:enrich")
  end

  it "downloads an enriched workbook for a valid upload" do
    uploaded = Rack::Test::UploadedFile.new(
      input_path,
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      true
    )
    post enrichments_path, params: { workbook: uploaded }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    expect(response.headers["Content-Disposition"]).to include("catalogo_enriquecido.xlsx")
    expect(response.body.bytesize).to be > 1000
  end

  it "rejects missing file" do
    post enrichments_path
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Selecciona un archivo")
  end

  it "rejects oversized uploads" do
    stub_const("EnrichmentsController::MAX_UPLOAD_BYTES", 10)

    uploaded = Rack::Test::UploadedFile.new(
      input_path,
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      true
    )
    post enrichments_path, params: { workbook: uploaded }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("10 MB")
  end




  it "rejects invalid origen headers" do
    Tempfile.create([ "bad", ".xlsx" ]) do |tmp|
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Origen") do |sheet|
        sheet.add_row(%w[Foo Bar])
      end
      package.serialize(tmp.path)

      uploaded = Rack::Test::UploadedFile.new(
        tmp.path,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        true,
        original_filename: "bad.xlsx"
      )
      post enrichments_path, params: { workbook: uploaded }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to match(/missing headers|Origen/i)
    end
  end
end
