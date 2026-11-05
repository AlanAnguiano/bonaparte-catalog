# frozen_string_literal: true

require "caxlsx"
require "fileutils"

module Catalog
  class WorkbookExporter
    ORIGEN_HEADERS = WorkbookImporter::ORIGEN_HEADERS

    APPLICATION_HEADERS = [
      "Referencia", "Marca", "Producto", "Posición", "Fabricante", "Modelo", "Submodelo",
      "Año", "Litros", "CC", "CID", "Cilindros", "Bloque", "Combustible", "Mercado"
    ].freeze

    INTERCHANGE_HEADERS = [
      "Referencia", "Marca", "Producto", "Intercambio", "Marca intercambio", "Origen"
    ].freeze

    ATTRIBUTE_HEADERS = [
      "Referencia", "Marca", "Producto", "Clase", "Atributo", "Unidad", "Valor"
    ].freeze

    CATALOG_HEADERS = [
      "Referencia", "Marca", "Categoría", "Sistema", "Subsistema", "Producto", "Descripción"
    ].freeze

    def self.call(result:, output_path:)
      new(result:, output_path:).call
    end

    def initialize(result:, output_path:)
      @result = result
      @output_path = output_path.to_s
    end

    def call
      FileUtils.mkdir_p(File.dirname(@output_path))

      package = Axlsx::Package.new
      workbook = package.workbook

      add_origen(workbook)
      add_metricas(workbook)
      add_table_sheet(workbook, "Aplicaciones", APPLICATION_HEADERS, @result.applications)
      add_table_sheet(workbook, "Intercambios", INTERCHANGE_HEADERS, @result.interchanges)
      add_table_sheet(workbook, "Atributos", ATTRIBUTE_HEADERS, @result.attributes)
      add_table_sheet(workbook, "Catálogo", CATALOG_HEADERS, @result.catalog)

      package.serialize(@output_path)
      @output_path
    end

    private

    def add_origen(workbook)
      workbook.add_worksheet(name: "Origen") do |sheet|
        sheet.add_row(ORIGEN_HEADERS)
        @result.origen.each do |product|
          sheet.add_row([
            product.internal_code,
            product.part_number,
            product.article_description,
            product.description,
            product.article_group,
            product.manufacturer,
            product.unit
          ])
        end
      end
    end

    def add_metricas(workbook)
      refs = @result.origen.size
      apps = @result.applications.size
      inter = @result.interchanges.size
      attrs = @result.attributes.size

      workbook.add_worksheet(name: "Métricas") do |sheet|
        sheet.add_row([ "Catálogo Bonaparte - Refaccionaria Trópico de Cáncer" ])
        sheet.add_row([ "Referencias:", refs ])
        sheet.add_row([])
        sheet.add_row([ "Aplicaciones", apps ])
        sheet.add_row([ "Origen", 0 ])
        sheet.add_row([ "Incrementos", apps ])
        sheet.add_row([])
        sheet.add_row([ "Intercambios", inter ])
        sheet.add_row([ "Origen", 0 ])
        sheet.add_row([ "Incrementos", inter ])
        sheet.add_row([])
        sheet.add_row([ "Atributos", attrs ])
        sheet.add_row([ "Origen", 0 ])
        sheet.add_row([ "Incrementos", attrs ])
      end
    end

    def add_table_sheet(workbook, name, headers, rows)
      workbook.add_worksheet(name: name) do |sheet|
        sheet.add_row(headers)
        rows.each do |row|
          sheet.add_row(headers.map { |h| row[h] })
        end
      end
    end
  end
end
