Rails.application.routes.draw do
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }

  get "/check", to: "check#check"

  post "/batch", to: "batch#create"
  get "/batch/:id", to: "batch#show"

  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end
end
