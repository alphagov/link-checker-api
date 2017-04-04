Rails.application.routes.draw do
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "/check-link", to: proc { [200, {}, [{}.to_json]] }

  post "/batch", to: proc { [202, {}, [{}.to_json]] }
  get "/batch/:id", to: proc { [200, {}, [{}.to_json]] }
end
