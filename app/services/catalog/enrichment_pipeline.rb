# frozen_string_literal: true

module Catalog
  class EnrichmentPipeline
    def self.call(input_path:, evidence_dir:, output_path:)
      new(input_path:, evidence_dir:, output_path:).call
    end

    def initialize(input_path:, evidence_dir:, output_path:)
      @input_path = input_path
      @evidence_dir = evidence_dir
      @output_path = output_path
    end

    def call
      products = WorkbookImporter.call(@input_path)
      evidence = EvidenceRepository.load(@evidence_dir)
      result = CatalogResolver.call(products:, evidence_repository: evidence)
      WorkbookExporter.call(result:, output_path: @output_path)
    end
  end
end
