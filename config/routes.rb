Rails.application.routes.draw do
  get "/healthcheck", to: proc { [200, {}, %w[OK]] }

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
  )

  get "/check", to: "check#check"

  post "/batch", to: "batch#create"
  get "/batch/:id", to: "batch#show"

  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end
end
