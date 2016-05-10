class App < Sinatra::Base
  enable :sessions

  # before do
  #   @user = User.get(session[:user])
  # end

  get '/' do
    if session[:user_id]
      @user = User.get(session[:user_id])
    elsif session[:parent_id]
      @parent = Parent.get(session[:parent_id])
    end
    erb :homepage
  end

  get '/login' do

    erb :login
  end

  post '/login/in' do
    if /.*[@].*/.match(params[:username_email])
      user = User.first(email_address: params[:username_email])
    elsif /[^\w]/.match(params[:username_email])
      ArgumentError
    else
      user = User.first(username: params[:username_email])
    end

    if /.*[@].*/.match(params[:username_email])
      parent = Parent.first(email_address: params[:username_email])
    elsif /[^\w]/.match(params[:username_email])
      ArgumentError
    else
      parent = Parent.first(username: params[:username_email])
    end

    if user && user.password == params[:password]
      session[:user_id] = user.id
    elsif parent && parent.password == params[:password]
      session[:parent_id] = parent.id
    end
    redirect '/'
  end

  get '/sign_up' do
    erb :sign_up
  end

  post '/sign_up/create' do
    if params[:parent_account]
      Parent.create(username: params[:username], password: params[:password], email_address: params[:email], details: params[:details])
    else
      User.create(username: params[:username], password: params[:password], email_address: params[:email], details: params[:details])
    end
  redirect '/'

  end

  post '/log_out' do
    session.destroy
    redirect '/'
  end

  get '/activities/simple' do
    if session[:user_id]
      @user = User.get(session[:user_id])
      @activity = Activity.all(user_id: session[:user_id])
    elsif session[:parent_id]
      @parent = Parent.get(session[:parent_id])
    end
    @event = true
    @simple = true
    erb :activity
  end

  get '/activities/calendar' do
    if session[:user_id]
      @user = User.get(session[:user_id])
      @activity = Activity.all(user_id: session[:user_id])
    elsif session[:parent_id]
      @parent = Parent.get(session[:parent_id])
    end
    @event = true
    @simple = true
    erb :activity
  end

  get '/new_activity' do
    if session[:user_id]
      @user = User.get(session[:user_id])
      @subjects = Subject.all(user_id: session[:user_id])
      @plans = Plan.all(user_id: session[:user_id])
    # elsif session[:parent]
      # @parent = session[:parent]
      # @subjects = Subject.all(parent_id: session[:parent].id)
      # @plans = Plan.all(parent_id: session[:parent].id)
    else
      ArgumentError
    end
    erb :new_activity
  end

  post '/create_activity' do
    if params[:hidden_activity] == "hidden"
      hidden = true
    else
      hidden = false
    end
    if session[:user_id]
      parent = false
      Activity.create(title: params[:title], type: params[:type], subject: params[:subject],
                      date: params[:due_date], planning: params[:planning],
                      hidden: hidden, parent: parent, user_id: session[:user_id])
    else
      parent = true
      # Activity.create(title: params[:title], type: params[:type], subject: params[:subject],
      #                 date: params[:due_date], planning: params[:planning],
      #                 hidden: hidden, parent: parent, user_id: session[:parent_id] )
    end
    redirect '/activities/simple'
  end

  get '/management' do
    if session[:user_id]
      @user = User.get(session[:user_id])
      @search = Parent.get(session[:search])
      @relative = @user.parents
      requests = ParentRequest.all(user_id: session[:user_id])
      @requesters = []
      for request in requests
        @requesters << Parent.get(request.id)
      end
    elsif session[:parent_id]
      @parent = Parent.get(session[:parent_id])
      @search = User.get(session[:search])
      @relative = @parent.users
      requests = UserRequest.all(:parent_id => session[:parent_id])
      @requesters = []
      for request in requests
        @requesters << User.get(request.id)
      end
      p "hej"
      p @requesters
    end
    erb :parent_management
  end

  post '/parent_validation' do
    search = Parent.first(username: params[:name])
    unless search == nil
      session[:search] = search.id
    end
    redirect back
  end

  post '/child_validation' do
    search = User.first(username: params[:name])
    unless search == nil
      session[:search] = search.id
    end
    redirect back
  end

  post '/user_request/?' do
    UserRequest.create(time: Time.now, requester_id: session[:user_id], parent_id: session[:search])

    redirect back
  end

  post '/parent_request/?' do
    ParentRequest.create(time: Time.now, requester_id: session[:parent_id], user_id: session[:search])

    redirect back
  end

  post '/remove_relative/:id/?' do |relative_id|
    if session[:user] != nil
      relation = ParentUser.get(relative_id, session[:user_id])
    else
      relation = ParentUser.get(session[:parent_id], relative_id)
    end
    relation.destroy
    redirect back
  end

  post '/confirmation/:id/?' do |request_id|
    if params[:option] == "Accept" && session[:parent_id]
      user = User.get(request_id)
      parent = Parent.get(session[:parent_id])
      parent.users << user
      parent.save
      request = UserRequest.first(:requester_id => request_id)
      request.destroy
    elsif params[:option] == "Decline" && session[:parent_id]
      request = UserRequest.first(:requester_id => request_id)
      request.destroy
    elsif params[:option] == "Accept" && session[:user_id]
      parent = Parent.get(request_id)
      user = User.get(session[:user_id])
      user.parents << parent
      user.save
      request = ParentRequest.first(:requester_id => request_id)
      request.destroy
    elsif params[:option] == "Decline" && session[:user_id]
      request = ParentRequest.first(:requester_id => request_id)
      request.destroy
    end
    redirect back
  end
end