require 'rails_helper'

RSpec.describe "Fullfilments", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/fulfillment/index"
      expect(response).to have_http_status(:success)
    end
  end

end
