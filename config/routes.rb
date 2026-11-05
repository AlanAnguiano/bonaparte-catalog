Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "enrichments#new"
  resources :enrichments, only: %i[new create]
end
