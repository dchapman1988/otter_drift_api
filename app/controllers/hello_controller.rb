class HelloController < ApplicationController

  def world
    render json: { "message": 'Hello World, and Flutter!' }
  end
end
