# frozen_string_literal: true

require "roo"

module Catalog
  class WorkbookImporter
    ORIGEN_HEADERS = [
      "Cod interno",
      "Número de parte",
      "Descripción del artículo",
      "Descripcion",
      "Grupo de articulos",
      "Fabricante",
      "Unidad"
    ].freeze

    SourceProduct = Data.define(
      :internal_code,
      :part_number,
      :article_description,
      :description,
      :article_group,
      :manufacturer,
      :unit
    )

    def self.call(input_path)
      new(input_path).call
    end

    def initialize(input_path)
      @input_path = input_path.to_s
    end

    def call
      raise InvalidWorkbookError, "File not found: #{@input_path}" unless File.file?(@input_path)

      book = Roo::Excelx.new(@input_path)
      unless book.sheets.include?("Origen")
        raise InvalidWorkbookError, "Missing required sheet 'Origen'"
      end

      sheet = book.sheet("Origen")
      raise InvalidWorkbookError, "Origen sheet has no rows" if sheet.last_row.nil? || sheet.last_row < 1

      headers = sheet.row(1).map { |h| normalize_header(h) }
      missing = ORIGEN_HEADERS - headers
      unless missing.empty?
        raise InvalidWorkbookError, "Origen missing headers: #{missing.join(', ')}"
      end

      index = ORIGEN_HEADERS.index_with { |h| headers.index(h) }

      products = []
      return products if sheet.last_row < 2

      (2..sheet.last_row).each do |row_num|
        row = sheet.row(row_num)
        next if row_blank?(row)

        part_number = cell_string(row[index["Número de parte"]])
        manufacturer = cell_string(row[index["Fabricante"]])
        if part_number.empty? || manufacturer.empty?
          raise InvalidWorkbookError,
                "Row #{row_num}: Número de parte and Fabricante are required"
        end

        products << SourceProduct.new(
          internal_code: normalize_internal_code(row[index["Cod interno"]]),
          part_number: part_number,
          article_description: cell_string(row[index["Descripción del artículo"]]),
          description: cell_string(row[index["Descripcion"]]),
          article_group: cell_string(row[index["Grupo de articulos"]]),
          manufacturer: manufacturer,
          unit: cell_string(row[index["Unidad"]])
        )
      end

      products
    end

    private

    def normalize_header(value)
      value.to_s.strip
    end

    def row_blank?(row)
      Array(row).all? { |c| c.nil? || c.to_s.strip.empty? }
    end

    def cell_string(value)
      return "" if value.nil?

      value.to_s.strip
    end

    def normalize_internal_code(value)
      return "" if value.nil?

      if value.is_a?(Numeric)
        return value.to_i.to_s if value == value.to_i

        return value.to_s
      end

      text = value.to_s.strip
      return text.to_i.to_s if text.match?(/\A\d+\.0+\z/)

      text
    end
  end
end
