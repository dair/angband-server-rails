class ApplicationController < ActionController::Base
  protect_from_forgery

  def setDefaultVars
    if (flash[:last_error])
      @last_error = flash[:last_error].join(", ")
    end
    @username = session[:username]
  end

  def render(options = nil, extra_options = {}, &block)
    setDefaultVars()
    super(options, extra_options, &block)
  end
  
  def id0(id)
    key = 0
    begin
      if (id)
        key = Integer(id)
      end
    rescue ArgumentError
      key = 0
    end
    return key
  end

  def addError(error)
    if !flash[:last_error]
      flash[:last_error] = []
    end
    flash[:last_error].append(error)
  end

  def index
    if (session[:user_id])
      redirect_to :action => "main"
    else
      render "layouts/login", :layout => false
    end
  end

  def login
    ret = false
    if (not session[:user_id])
      id = params[:name]
      passwd = params[:password]

      ret = AngbandDb.checkLogin(id, passwd)
    else
      id = session[:user_id]
      name = session[:username]
      ret = true
    end

    if (ret)
      session[:user_id] = id
      session[:username] = AngbandDb.getOperatorName(id)
      redirect_to :action => "main"
    else
      redirect_to :action => "index"
    end
  end

  def logout
    session[:user_id] = nil
    session[:username] = nil
    redirect_to :action => "index"
  end

  def checkCredentials
    if (not session[:user_id])
      redirect_to :action => "index"
      return false
    end
    return true
  end

  def main
    if not checkCredentials()
      return
    end
    render "index"
  end

  def events
    if not checkCredentials()
      return
    end
  end

  def event
    if not checkCredentials()
      return
    end
    
    id = id0(params[:id])
    if (id == 0)
        redirect_to :action => "event_edit", :id => params[:id]
    end
    @event = params[:id]
  end

  def event_edit
    if not checkCredentials()
      return
    end
    
    id = id0(params[:id])
    if (id == 0)
      @event = Hash.new
      @event["id"] = id
    else
      @event = AngbandDb.getEvent(id)
    end
  end

  def event_write
    if not checkCredentials()
      return
    end

#    puts "WEEEEEEE"
#    puts params
#    puts "WEEEEEEE"

    event = Hash.new
    event["title"] = params["title"].strip
    event["objects_str"] = params[:objects].strip
    event["location_str"] = params[:location].strip
    event["desc"] = params[:description]
    event["id"] = id0(params[:id])

    AngbandDb.writeEvent(event)
    
    redirect_to :action => "event", :id => params[:id]
  end

  def map
    render "map", :layout => false
  end
end

