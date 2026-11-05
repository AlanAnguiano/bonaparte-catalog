# frozen_string_literal: true

require "yaml"

module Catalog
  class EvidenceRepository
    def self.load(evidence_dir)
      new(evidence_dir)
    end

    def initialize(evidence_dir)
      @evidence_dir = evidence_dir.to_s
      raise Error, "Evidence directory not found: #{@evidence_dir}" unless File.directory?(@evidence_dir)

      @by_key = {}
      load_all!
    end

    def find(part_number:, manufacturer:)
      @by_key[key_for(part_number, manufacturer)]
    end

    def size
      @by_key.size
    end

    private

    def load_all!
      Dir[File.join(@evidence_dir, "*.yml")].sort.each do |path|
        payload = YAML.safe_load_file(path, permitted_classes: [ Date, Time ], aliases: true)
        next unless payload.is_a?(Hash)

        source = payload["source_product"]
        next unless source.is_a?(Hash)

        part = source["part_number"]
        brand = source["manufacturer"]
        next if part.to_s.strip.empty? || brand.to_s.strip.empty?

        @by_key[key_for(part, brand)] = payload
      end
    end

    def key_for(part_number, manufacturer)
      "#{part_number.to_s.strip.upcase}|#{manufacturer.to_s.strip.upcase}"
    end
  end
end
