Rails.application.routes.draw do
  get 'fulfillment/index'
  get 'fulfillment/to-increase-stock', to: 'fulfillment#to_increase_stock'
  get 'seller/index'
  get 'seller/auth-all', to: 'seller#auth_all'
  post 'seller/create', to: 'seller#create'
  post 'seller/edit', to: 'seller#edit'
  post 'seller/delete', to: 'seller#delete'
  post 'item/add-stock', to: 'item#add_stock'
  get 'item/retrieve-item', to: 'item#retrieve_item'
  get 'item/price-events', to: 'item#price_events'
  get 'item/logistic-events', to: 'item#logistic_events'
  get 'item/free-shipping', to: 'item#free_shipping'
  post 'item/free-shipping', to: 'item#change_to_free_shipping'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
