# coding: UTF-8

# ##################################################################
# Angband Informational Center
# For First Age LARP (http://firstage2013.ru)
# by Vladimir "Dair" Lebedev-Schmidthof <dair@albiongames.org>
# Mk. Albion (http://albiongames.org)
# 
# Copyright (c) 2013 Vladimir Lebedev-Schmidthof
# ##################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# This file is also provided in the root directory of this project
# as LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
#    if (session[:user_id])
      redirect_to :action => "main"
#    else
#      render "layouts/login", :layout => false
#    end
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
#    if (not session[:user_id])
#      redirect_to :action => "index"
#      return false
#    end
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
    if roles.kind_of? Array
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
    else
        redirect_to :controller => "reader", :action => "events"
        return
    end

    @roles = roles
  end

end

