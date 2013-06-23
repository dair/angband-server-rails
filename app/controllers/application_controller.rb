# coding: UTF-8

class ApplicationController < ActionController::Base
  protect_from_forgery

  def setDefaultVars
    if (flash[:last_error])
      @last_error = flash[:last_error]
    else
      @last_error = nil
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
      flash[:last_error] = Array.new
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
      roles = []
      if ret
        roles = AngbandDb.getOperatorRoles(id)
      end
    else
      id = session[:user_id]
      name = session[:username]
      roles = session[:userroles]
      ret = true
    end

    if !ret
      addError("Имя/пароль неправильные")
      redirect_to :action => "index"
      return
    end

    if not roles or roles.empty?
      addError("Роли для пользователя не заданы. Обратитесь к администратору")
      redirect_to :action => "index"
      return
    end

    session[:user_id] = id
    session[:username] = AngbandDb.getOperatorName(id)
    session[:userroles] = roles

    timezone = params["timezone"].to_i
    hours = timezone / 60
    minutes = timezone % 60
    timezone = "%d:%02d" % [hours, minutes]
    session[:timezone] = timezone

    redirect_to :action => "main"
  end

  def logout
    session[:user_id] = nil
    session[:username] = nil
    session[:userroles] = nil
    redirect_to :action => "index"
  end

  def checkCredentials
    if (not session[:user_id])
      redirect_to :action => "index"
      return false
    end
    return true
  end

  def splitString(s)
    return s.split(/ +/)
  end

  def main
    if not checkCredentials
        return
    end
    roles = session[:userroles]
    if roles.size == 1
        case roles[0]
            when 'A'
                redirect_to :controller => "admin", :action => "main"
            when 'W' # writer
                redirect_to :controller => "writer", :action => "main"
            when 'R'
                redirect_to :controller => "reader", :action => "main"
        end
        return
    end

    @roles = roles
  end

end

