# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

require Rails.root.join("lib/phloem/cors_origins")

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end

allowed_cors_origins = Phloem::CorsOrigins.parse

if allowed_cors_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_cors_origins)

      resource "/route",
        headers: %w[Content-Type Authorization X-API-Key],
        methods: [:post, :options],
        max_age: 600
    end
  end
end
