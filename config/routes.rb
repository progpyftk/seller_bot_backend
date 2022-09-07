Rails.application.routes.draw do
  get 'fulfillment/index'
  get 'fulfillment/to-increase-stock', to: 'fulfillment#to_increase_stock'
  get 'seller/index'
  get 'seller/auth-all', to: 'seller#auth_all'
  post 'seller/create', to: 'seller#create'
  post 'item/add-stock', to: 'item#add_stock'
  get 'item/retrieve-item', to: 'item#retrieve_item'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
