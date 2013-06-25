# coding: UTF-8

class WriterController < ApplicationController
    protect_from_forgery
    alias parent_checkCredentials checkCredentials

    def checkCredentials
        if !parent_checkCredentials
            return false
        end

        if session[:userroles].kind_of? Array and \
           session[:userroles].include? 'W'
            return true
        end

        redirect_to :controller => "application", :action => "main"
        return false
    end
    
    def main
        if not checkCredentials
            return
        end
        if session["event_edit"]
            @event = session["event_edit"]
            session["event_edit_prev"] = session["event_edit"]["old"]
            session["event_edit"] = nil
        elsif params["id"]
            id = id0(params["id"])
            @event = AngbandDb.getEvent(id, session["timezone"])
        else
            @event = Hash.new
        end
        @all_objects = AngbandDb.getAllObjectNames()
        @all_locations = AngbandDb.getAllLocationNames()
        @all_reporters = AngbandDb.getAllReporterNames()
        @all_tags = AngbandDb.getAllTagNames()

        render "main"
    end

    def event_params(params)
        ret = params.clone
        ret.each { |k, v| ret[k] = v.strip }

        if ret["title"].length == 0
            is_error = true
            addError("Заголовок пустым быть не может")
        end

        objs = splitString(ret["objects"])
        ret["objects"] = objs
        if objs.length == 0
            addError("Нужен хотя бы один объект")
            is_error = true
        end

        locations = splitString(ret["location"])
        if locations.length != 1
            addError("Локация должна быть одна")
            is_error = true
        else
            ret["location"] = locations[0]
        end

        reporters = splitString(ret["reporter"])
        if reporters.length != 1
            addError("Источник должен быть один")
            is_error = true
        else
            ret["reporter"] = reporters[0]
        end

        tags = splitString(ret["tags"])
        ret["tags"] = tags
        
        importance = id0(ret["importance"])
        ret["importance"] = importance

        ret["in_game"] = (ret["in_game"] == "1")

        return {:error => is_error, :data => ret}
    end

    def event_write
        if not checkCredentials
            return
        end

        event_pair = event_params(params)

        if event_pair[:error]
            session["event_edit"] = params
            redirect_to :action => "main"
        else
            event = event_pair[:data]

            if session["event_edit_prev"]
                old = session["event_edit_prev"]
                old_event_pair = event_params(old)
                old_event = old_event_pair[:data]

                session["event_edit_prev"] = nil

                if event == old_event
                    # weeeee, confirmed
                    ret = event_actual_write(event)
                    if ret
                        session["event_edit"] = nil
                        addError("Событие успешно сохранено")
                    else
                        #puts "=============================================="
                        #puts session["event_edit"]
                        #puts "=============================================="
                    end
                    redirect_to :action => "main"
                    return
                end
            end

            new_objs = AngbandDb.getUnknownObjects(event["objects"]) # array
            new_location = AngbandDb.getUnknownLocation(event["location"]) # string
            new_reporter = AngbandDb.getUnknownReporter(event["reporter"]) # string
            new_tags = AngbandDb.getUnknownTags(event["tags"])

            if new_objs.empty? and new_location.length == 0 and new_reporter.length == 0 and new_tags.empty?
                # weeeee, nothing new, just write and next
                ret = event_actual_write(event)
                if ret
                    session["event_edit"] = nil
                    addError("Событие успешно сохранено")
                else
                    #puts "=============================================="
                    #puts session["event_edit"]
                    #puts "=============================================="
                end
            else
                params["old"] = params.clone

                if not new_objs.empty?
                    params["new_objects"] = new_objs
                end

                if new_location.length > 0
                    params["new_location"] = new_location
                end

                if new_reporter.length > 0
                    params["new_reporter"] = new_reporter
                end

                if not new_tags.empty?
                    params["new_tags"] = new_tags
                end

                session["event_edit"] = params
            end
            redirect_to :action => "main"
        end
    end

    def event_actual_write(event)
        event["id"] = id0(event["id"])
        ret = AngbandDb.writeEvent(event, session[:user_id])
        if ret[:error]
            addError(ret[:error])
            addError(ret[:error_trace])
            return false
        end
        return true
    end

    def events
        if not checkCredentials
            return
        end

        @params = params
        if not params
            @params = Hash.new
        end
        if not @params["from"]
            @params["from"] = 0
        end
        if not @params["qty"]
            @params["qty"] = 100
        end
        
        filters = {}
        if params["obj_id"]
            filters["objects"] = [params["obj_id"]]
        end
        events = AngbandDb.getEventList(id0(@params["from"]), id0(@params["qty"]), session[:timezone], filters)

        @params["events"] = events
    end

    def event
        main
    end

    def event_delete
        if not checkCredentials
            return
        end

        id = id0(params["id"])
        if id > 0
            AngbandDb.deleteEvent(id)
        end
        redirect_to :action => "events"
    end

################### OBJECT

    def objects
        if not checkCredentials
            return
        end

        if not params
            @params = Hash.new
        else
            @params = params
        end
        if not @params["from"]
            @params["from"] = 0
        end
        if not @params["qty"]
            @params["qty"] = 100
        end
       
        objects = AngbandDb.getObjectList(id0(@params["from"]), id0(@params["qty"]), session[:timezone])
        for obj in objects
            if obj["description"] and obj["description"].length > 50
                obj["description"] = obj["description"][0, 50] + "..."
            end
        end

        @params["objects"] = objects
    end

    def object
        if not checkCredentials
            return
        end

        id = id0(params["id"])
        if session["object"]
            object = session["object"]
            session["object"] = nil
        elsif id > 0
            object = AngbandDb.getObject(id, session["timezone"])
            object["parent"] = AngbandDb.getObjectParent(id)
        else
            object = Hash.new
            object["id"] = 0
        end
        
        incs = AngbandDb.getObjectIncludes(id)
        object["children"] = incs[0]
        object["not_children"] = incs[1]
        
        @object = object
    end

    def object_write
        if not checkCredentials
            return
        end

        id = id0(params["id"])

        params["name"] = params["name"].strip
        params["description"] = params["description"].strip

        if params["name"].empty?
            addError("Имя пустым быть не должно")
            session["object"] = params
            redirect_to :action => "object"
            return
        end

        found_id = id0(AngbandDb.findObjectByName(params["name"]))
        if found_id > 0 and id != found_id
            addError("Объект с таким именем уже есть")
            session["object"] = params
            redirect_to :action => "object"
            return
        end

        params["id"] = id
        id = AngbandDb.writeObject(params, session[:user_id])

        children = params["children_list"].split(" ")
        AngbandDb.setObjectChildren(id, children)
        redirect_to :action => "objects"
    end

    def object_delete
        if not checkCredentials
            return
        end

        id = id0(params["id"])

        AngbandDb.deleteObject(id)

        redirect_to :action => "objects"
    end

    def locations
        if not checkCredentials
            return
        end

        locations = AngbandDb.getLocationList()
        @params = Hash.new
        @params["locations"] = locations
    end

    def location
        if not checkCredentials
            return
        end

        id = id0(params["id"])
        if session["location"]
            location = session["location"]
            session["location"] = nil
        elsif id > 0
            location = AngbandDb.getLocation(id)
            evts = AngbandDb.getEventsByLocation(id)
            location["events"] = evts.length
        else
            location = Hash.new
            location["id"] = 0
        end

        @location = location
    end

    def location_write
        if not checkCredentials
            return
        end

        id = id0(params["id"])

        params["name"] = params["name"].strip

        if params["name"].empty?
            addError("Имя пустым быть не должно")
            session["location"] = params
            redirect_to :action => "location"
            return
        end

        found_id = id0(AngbandDb.findLocationByName(params["name"]))
        if found_id > 0 and id != found_id
            addError("Локация с таким именем уже есть")
            session["location"] = params
            redirect_to :action => "location"
            return
        end

        params["id"] = id
        AngbandDb.writeLocation(params, session[:user_id])
        redirect_to :action => "locations"
    end

    def location_delete
        if not checkCredentials
            return
        end

        id = id0(params["id"])
        if id > 0
            AngbandDb.deleteLocation(id)
        end
        redirect_to :action => "locations"
    end

end

