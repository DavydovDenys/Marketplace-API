class HomeController < ApplicationController
  def home
    render json: { message: 'Hello From Render' }
  end
end
