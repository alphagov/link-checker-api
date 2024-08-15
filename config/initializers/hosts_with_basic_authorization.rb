if Rails.application.credentials.govuk_basic_auth_credentials
  govuk_website_host = URI(Plek.website_root).host.to_s
  LinkCheckerApi.hosts_with_basic_authorization[govuk_website_host] = Rails.application.credentials.govuk_basic_auth_credentials
end
