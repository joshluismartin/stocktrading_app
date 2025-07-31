class ErrorsController < ApplicationController
  def errors
    render "errors", status: :not_found
  end

  def internal_server_error
    render "internal_server_error", status: :internal_server_error
  end
end
