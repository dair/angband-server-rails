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

