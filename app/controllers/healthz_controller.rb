# frozen_string_literal: true

class HealthzController < ApplicationController
  def index
    render json: params
  end

  def create
    render json: params
  end
end
