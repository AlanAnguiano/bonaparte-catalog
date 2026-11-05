# frozen_string_literal: true

namespace :catalog do
  desc "Enrich an Origen workbook using versioned evidence/ YAML (deterministic, no network)"
  task enrich: :environment do
    input = ENV.fetch("INPUT") do
      Dir[Rails.root.join("data/data_prueba*.xlsx")].min ||
        raise("INPUT not set and no data/data_prueba*.xlsx found")
    end
    output = ENV.fetch("OUTPUT") { Rails.root.join("output/catalogo_enriquecido.xlsx").to_s }
    evidence_dir = ENV.fetch("EVIDENCE_DIR") { Rails.root.join("evidence").to_s }

    path = Catalog::EnrichmentPipeline.call(
      input_path: input,
      evidence_dir: evidence_dir,
      output_path: output
    )

    puts "Wrote #{path}"
  end
end
