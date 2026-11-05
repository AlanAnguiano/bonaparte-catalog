# frozen_string_literal: true

module Catalog
  class CatalogResolver
    Result = Data.define(:origen, :applications, :interchanges, :attributes, :catalog)

    def self.call(products:, evidence_repository:)
      new(products:, evidence_repository:).call
    end

    def initialize(products:, evidence_repository:)
      @products = products
      @evidence = evidence_repository
    end

    def call
      applications = []
      interchanges = []
      attributes = []
      catalog = []

      @products.each do |product|
        evidence = @evidence.find(
          part_number: product.part_number,
          manufacturer: product.manufacturer
        )
        next unless evidence

        product_name = append_catalog_row!(catalog, product, evidence)
        append_applications!(applications, product, product_name, evidence)
        append_interchanges!(interchanges, product, product_name, evidence)
        append_attributes!(attributes, product, product_name, evidence)
      end

      Result.new(
        origen: @products,
        applications: sort_applications(applications),
        interchanges: sort_interchanges(interchanges),
        attributes: sort_attributes(attributes),
        catalog: sort_catalog(catalog)
      )
    end

    private

    def append_catalog_row!(catalog, product, evidence)
      catalog_meta = evidence["catalog"] || {}
      product_name = catalog_meta["product"].to_s

      catalog << {
        "Referencia" => product.part_number,
        "Marca" => product.manufacturer,
        "Categoría" => catalog_meta["category"].to_s,
        "Sistema" => catalog_meta["system"].to_s,
        "Subsistema" => catalog_meta["subsystem"].to_s,
        "Producto" => product_name,
        "Descripción" => catalog_meta["description_template"].to_s.strip
      }

      product_name
    end

    def append_applications!(applications, product, product_name, evidence)
      Array(evidence["applications"]).each do |app|
        next unless truthy?(app["export"])

        year_from, year_to = year_range_for(app, product)
        (year_from..year_to).each do |year|
          applications << {
            "Referencia" => product.part_number,
            "Marca" => product.manufacturer,
            "Producto" => product_name,
            "Posición" => blank_to_nil(app["position"]),
            "Fabricante" => app["vehicle_make"].to_s,
            "Modelo" => app["model"].to_s,
            "Submodelo" => blank_to_nil(app["submodel"]),
            "Año" => year,
            "Litros" => numeric_or_nil(app["liters"]),
            "CC" => numeric_or_nil(app["cc"]),
            "CID" => numeric_or_nil(app["cid"]),
            "Cilindros" => numeric_or_nil(app["cylinders"]),
            "Bloque" => blank_to_nil(app["block"]),
            "Combustible" => blank_to_nil(app["fuel"]),
            "Mercado" => blank_to_nil(app["market"])
          }
        end
      end
    end

    def append_interchanges!(interchanges, product, product_name, evidence)
      Array(evidence["interchanges"]).each do |row|
        next unless truthy?(row["export"])

        interchanges << {
          "Referencia" => product.part_number,
          "Marca" => product.manufacturer,
          "Producto" => product_name,
          "Intercambio" => row["part_number"].to_s,
          "Marca intercambio" => row["brand"].to_s,
          "Origen" => row["origin"].to_s
        }
      end
    end

    def append_attributes!(attributes, product, product_name, evidence)
      Array(evidence["attributes"]).each do |row|
        next unless truthy?(row["export"])

        attributes << {
          "Referencia" => product.part_number,
          "Marca" => product.manufacturer,
          "Producto" => product_name,
          "Clase" => row["class"].to_s,
          "Atributo" => row["name"].to_s,
          "Unidad" => blank_to_nil(row["unit"]),
          "Valor" => stringify_value(row["value"])
        }
      end
    end

    def year_range_for(app, product)
      year_from = Integer(app["year_from"])
      year_to = Integer(app["year_to"] || app["year_from"])
      [ year_from, year_to ]
    rescue ArgumentError, TypeError
      raise Error,
            "Invalid application year range in evidence for #{product.part_number} / #{product.manufacturer}"
    end

    def truthy?(value)
      value == true || value.to_s.downcase == "true"
    end

    def blank_to_nil(value)
      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def numeric_or_nil(value)
      return nil if value.nil? || value.to_s.strip.empty?

      text = value.to_s.strip
      return text.to_i if text.match?(/\A-?\d+\z/)
      return text.to_f if text.match?(/\A-?\d+\.\d+\z/)

      text
    end

    def stringify_value(value)
      return "" if value.nil?

      value.to_s
    end

    def sort_applications(rows)
      rows.sort_by do |r|
        [
          r["Referencia"].to_s,
          r["Fabricante"].to_s,
          r["Modelo"].to_s,
          r["Submodelo"].to_s,
          r["Año"].to_i,
          r["Litros"].to_s,
          r["CC"].to_s,
          r["CID"].to_s,
          r["Combustible"].to_s,
          r["Mercado"].to_s
        ]
      end
    end

    def sort_interchanges(rows)
      rows.sort_by do |r|
        [
          r["Referencia"].to_s,
          r["Marca intercambio"].to_s,
          r["Intercambio"].to_s,
          r["Origen"].to_s
        ]
      end
    end

    def sort_attributes(rows)
      rows.sort_by do |r|
        [
          r["Referencia"].to_s,
          r["Clase"].to_s,
          r["Atributo"].to_s,
          r["Unidad"].to_s,
          r["Valor"].to_s
        ]
      end
    end

    def sort_catalog(rows)
      rows.sort_by { |r| r["Referencia"].to_s }
    end
  end
end
