class PagesController < ApplicationController
  CheckitResult = Struct.new(:status, :valid_cert, :is_redirect, :is_error, :redirect_perm, :redirect_dest)
  ERROR_MESSAGE = "Please enter a URL or domain name"

  before_action :authenticate_user!, only: [
    :inside
  ]


  def home
    redirect_to projects_path if current_user
  end


  def checkit
  	# Validate and clean up the input
  	user_input = params[:url_or_domain_name].strip
    unless /\A[[:alnum:]\-.]{4,63}\z/ === user_input  # Just a safety check:
      flash[:alert] = ERROR_MESSAGE                   # valid characters & length
    	redirect_to root_path
      return
    end

    test_results = check(user_input)
    @valid_cert  = test_results.valid_cert
    if test_results.is_redirect
      @redirect_kind = test_results.redirect_perm ? 'permanent' : 'temporary'
      @redirect_dest = test_results.redirect_dest
      render 'checkit_with_redirect'
    elsif test_results.is_error
      render 'checkit_with_error'
    else
      @http_status = test_results.status
      render 'checkit_no_redirect'
    end
  end
  

  private
  def check(url_or_domain_name)
    CheckitResult.new(200, true, false)  # Kinda shitty that Struct doesn't do keyword args
  end

end
