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

require 'csv'

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

                unless event.has_key?("importance")
                    event["importance"] = 1
                end
                unless event.has_key?("in_game")
                    event["in_game"] = false
                end
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
            @params["qty"] = 1000
        end
        
        filters = {}
        if params["obj_id"]
            filters["objects"] = {}
            filters["objects"]["ids"] = [params["obj_id"]]
            obj = AngbandDb.getObject(params["obj_id"], session["timezone"])
            filters["objects"]["names"] = [obj["name"]]
        end
        
        if params["loc_id"]
            filters["locations"] = {}
            filters["locations"]["ids"] = [params["loc_id"]]
            loc = AngbandDb.getLocation(params["loc_id"])
            filters["locations"]["names"] = [loc["name"]]
        end

        if params["tag_id"]
            filters["tags"] = {}
            filters["tags"]["ids"] = [params["tag_id"]]
            tag = AngbandDb.getTag(params["tag_id"])
            filters["tags"]["names"] = [tag["name"]]
        end

        (events, count) = AngbandDb.getEventList(id0(@params["from"]), id0(@params["qty"]), session[:timezone], filters)

        @params["filters"] = filters
        @params["events"] = events
        @params["count"] = count
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
       
        (objects, count) = AngbandDb.getObjectList(id0(@params["from"]), id0(@params["qty"]), session[:timezone])
        for obj in objects
            if obj["description"] and obj["description"].length > 50
                obj["description"] = obj["description"][0, 50] + "..."
            end
        end

        @params["objects"] = objects
        @params["count"] = count
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

    def event_do_search
        if not checkCredentials
            return
        end

        s = params["substring"].strip
        if s.length == 0
            redirect_to "events"
            return
        end

        event_ids = AngbandDb.searchEventBySubstring(params["substring"])
        filters = {}
        filters["events"] = {}
        filters["events"]["ids"] = event_ids
        if event_ids.empty?
            events = []
            count = 0
        else
            (events, count) = AngbandDb.getEventList(0, 0, session[:timezone], filters)
        end
        @params = {}
        @params["filters"] = filters
        @params["events"] = events
        @params["count"] = count

        render "events"
    end

    def map_image
        if params["image"] and params["image"].length > 0
            file = IO.read(Rails.root.to_s + "/tmp/" + session[:user_id] + "_" + params["image"])
        else
            file = IO.read(Rails.root.to_s + "/public/map.jpg")
        end

        send_data file, :type => "image/jpg", :disposition => "inline"
    end

    def map
        period = 24 # hours
        if params["period"]
            period = params["period"].to_i
        end
    
        @params = {}
        @params["period"] = period
        @refresh = 5*60

        counts = AngbandDb.eventMap(period)
        imageMap = readImageMap

        max_qty = 0
        for c in counts
            if max_qty < c["count"].to_i
                max_qty = c["count"].to_i
            end
        end
        puts '==================='
        puts max_qty
        puts '==================='
        
        source = Rails.root.to_s + "/public/map.jpg"
        baseSource = source
        imageParam = ""

        outPath = Rails.root.to_s + "/tmp/" + session[:user_id] + "_"
        
        locations = []

        unknown_x = 0

        if max_qty > 0
            currentTmp = ""
            counter = 0
            for c in counts
                im = imageMap[c["name"]]
                count = c["count"].to_i
                percent = count * 100 / max_qty

                # generate picture
                numPath = dummypic(count, percent)

                if im
                    x = im["x"]
                    y = im["y"]
                else
                    x = unknown_x
                    y = 0
                    unknown_x += 30
                end
                new_out = outPath + counter.to_s + ".png"
                blendTo(source, x, y, numPath, new_out)
                #if source != baseSource
                #    File.delete(source)
                #end
                source = new_out
                imageParam = counter.to_s + ".png"
                locations.append({"id" => c["id"], "name" => c["name"], "x" => x, "y" => y })
                
                counter += 1
            end
        end

        @params["image"] = imageParam
        @params["locations"] = locations
    end

    def dummypic(count, percent)
        dummypicPath = Rails.root.to_s + "/lib/assets/dummypic"
        resPath = Rails.root.to_s + "/public/images/" + count.to_s + "_" + percent.to_s + ".png"
        if not File.exist?(resPath)
            system("#{dummypicPath} 30x30 #{percent} #{count} #{resPath}")
        end

        return resPath
    end

    def blendTo(source, x, y, num, out)
        system("composite -geometry +#{x}+#{y} #{num} #{source} #{out}")
    end

    def readImageMap
        ret = {}
        path = Rails.root
        
        CSV.foreach(path.to_s + "/public/loc-map.txt", :headers => false) do |row|
            if row[2]
                position = {}
                position["x"] = row[0].to_i
                position["y"] = row[1].to_i
                ret[row[2]] = position
            end
        end

        return ret
    end

    def tags
        if not checkCredentials
            return
        end

        tags = AngbandDb.getTagList()
        @params = {}
        @params["tags"] = tags
    end
end

