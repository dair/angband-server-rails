# coding: UTF-8

class ReaderController < ApplicationController
  protect_from_forgery

  def main
    if not checkCredentials()
      return
    end
    render "main"
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


  def map
    render "map", :layout => false
  end

end

