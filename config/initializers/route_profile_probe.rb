Rails.application.config.after_initialize do
  probe_on_boot_default = Rails.env.test? ? "false" : "true"
  probe_on_boot = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch("PHLOEM_PROFILE_PROBE_ON_BOOT", probe_on_boot_default)
  )

  if probe_on_boot
    begin
      RouteProfileProbe.run!
    rescue StandardError => error
      Rails.logger&.error("Route profile probe failed during boot: #{error.class}: #{error.message}")
      RouteProfileCatalog.apply_probe_result!(available_profiles: [], failures: {})
    end
  else
    RouteProfileCatalog.use_configured_profiles!
  end
end
