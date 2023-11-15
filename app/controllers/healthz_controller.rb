# frozen_string_literal: true

class HealthzController < ApplicationController
  def index
    redis.new
    render json: params
  end

  def create
    render json: params
  end
end
