Rails.application.routes.draw do
  get 'welcome/index'
  post "callback" => "webhook#callback"
  get "callback" => "webhook#callback_text"
  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
