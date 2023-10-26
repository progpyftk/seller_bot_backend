require 'sidekiq/web'


Rails.application.routes.draw do
  get 'fulfillment/index', to: 'fulfillment#index'
  get 'fulfillment/to-increase-stock', to: 'fulfillment#to_increase_stock'
  get 'fulfillment/flex', to: 'fulfillment#flex'
  post 'fulfillment/flex', to: 'fulfillment#flex_turn_off'
  post 'fulfillment/flex', to: 'fulfillment#flex_turn_on'
  get 'seller/index'
  get 'seller/promotions', to: 'seller#promotions'
  get 'seller/active-items', to: 'seller#active_items'  
  get 'seller/auth-all', to: 'seller#auth_all'
  post 'seller/create', to: 'seller#create'
  post 'seller/edit', to: 'seller#edit'
  post 'seller/delete', to: 'seller#delete'
  post 'seller/promotion-data', to: 'seller#promotion_data'
  post 'seller/activate-promotion', to: 'seller#activate_promotion'
  post 'item/add-stock', to: 'item#add_stock'
  get 'item/retrieve-item', to: 'item#retrieve_item'
  get 'item/price-events', to: 'item#price_events'
  get 'item/logistic-events', to: 'item#logistic_events'
  get 'item/free-shipping', to: 'item#free_shipping'
  get 'item/update-database', to: 'item#update_database'
  post 'item/free-shipping', to: 'item#change_to_free_shipping'
  post 'item/fiscal-data', to: 'item#fiscal_data'
  post 'item/general-data', to: 'item#general_data'
  post 'webhook/handle', to: 'webhook#handle'
  get 'webhook/update-tiny-stock', to: 'webhook#tiny_dp_update'
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users,
             path: '',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               registration: 'signup'
             },
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations'
             }

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
