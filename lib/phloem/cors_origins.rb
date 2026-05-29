module Phloem
  module CorsOrigins
    module_function

    def parse(value = ENV["PHLOEM_CORS_ORIGINS"])
      value.to_s.split(",").map(&:strip).reject(&:empty?)
    end
  end
end