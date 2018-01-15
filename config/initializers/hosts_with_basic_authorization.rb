if Rails.application.secrets.govuk_basic_auth_credentials
  LinkCheckerApi.hosts_with_basic_authorization[Plek.new.website_uri.host.to_s] = Rails.application.secrets.govuk_basic_auth_credentials
end
