# frozen_string_literal: true

class EnrichmentsController < ApplicationController
  MAX_UPLOAD_BYTES = 10.megabytes
  OUTPUT_FILENAME = "catalogo_enriquecido.xlsx"
  XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  def new
  end

  def create
    upload = params[:workbook]
    error = validate_upload(upload)
    if error
      return render_form_error(error)
    end

    send_enriched_workbook(upload)
  rescue Catalog::InvalidWorkbookError, Catalog::Error => e
    render_form_error(e.message)
  end

  private

  def validate_upload(upload)
    return "Selecciona un archivo Excel (.xlsx)." if upload.blank?

    name = upload.original_filename.to_s
    return "El archivo debe ser .xlsx." unless name.downcase.end_with?(".xlsx")

    size = upload.respond_to?(:size) ? upload.size : upload.tempfile.size
    return "El archivo supera el límite de 10 MB." if size.to_i > MAX_UPLOAD_BYTES

    nil
  end

  def send_enriched_workbook(upload)
    input_tmp = Tempfile.new([ "enrichment-input", ".xlsx" ])
    output_tmp = Tempfile.new([ "enrichment-output", ".xlsx" ])

    begin
      input_tmp.binmode
      input_tmp.write(upload.read)
      input_tmp.flush
      input_tmp.close
      output_tmp.close

      Catalog::EnrichmentPipeline.call(
        input_path: input_tmp.path,
        evidence_dir: Rails.root.join("evidence"),
        output_path: output_tmp.path
      )

      send_data File.binread(output_tmp.path),
                filename: OUTPUT_FILENAME,
                type: XLSX_CONTENT_TYPE,
                disposition: "attachment"
    ensure
      input_tmp.close!
      output_tmp.close!
    end
  end

  def render_form_error(message)
    @error = message
    render :new, status: :unprocessable_content
  end
end
