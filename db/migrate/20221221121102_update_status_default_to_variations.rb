class UpdateStatusDefaultToVariations < ActiveRecord::Migration[6.1]
  def change
    change_column_default :variations, :created_at, from: nil, to: -> { 'current_timestamp' }
    change_column_default :variations, :updated_at, from: nil, to: -> { 'current_timestamp' }
  end
end
