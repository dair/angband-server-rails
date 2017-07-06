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

class ReaderController < ApplicationController
    protect_from_forgery

    def main
        redirect_to :controller => "reader", :action => "events"
    end

    def events
        @params = params
        if not params
            @params = Hash.new
        end
        if not @params["from"]
            @params["from"] = 0
        end
        if not @params["qty"]
            @params["qty"] = 10
        end
        
        filters = {}
        if params["obj_id"]
            filters["objects"] = {}
            filters["objects"]["ids"] = [params["obj_id"]]
            obj = AngbandDb.getObject(params["obj_id"])
            filters["objects"]["names"] = [obj["name"]]
        end
        
        if params["loc_id"]
            filters["locations"] = {}
            filters["locations"]["ids"] = [params["loc_id"]]
            loc = AngbandDb.getLocation(params["loc_id"])
            filters["locations"]["names"] = [loc["name"]]
        end
        (events, count) = AngbandDb.getEventList(id0(@params["from"]), id0(@params["qty"]), filters)

        @params["filters"] = filters
        @params["events"] = events
        @params["count"] = count
    end

    def event
        id = id0(params["id"])
        if id == 0
            redirect_to :action => "events"
            return
        end

        @event = AngbandDb.getEvent(id)
    end

    def objects
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
       
        (objects, count) = AngbandDb.getObjectList(id0(@params["from"]), id0(@params["qty"]))
        for obj in objects
            if obj["description"] and obj["description"].length > 50
                obj["description"] = obj["description"][0, 50] + "..."
            end
        end

        @params["objects"] = objects
        @params["count"] = count
    end

    def object
        id = id0(params["id"])
        if id == 0
            redirect_to :action => "objects"
            return
        end
        
        object = AngbandDb.getObject(id)
        object["parent"] = AngbandDb.getObjectParent(id)
        
        
        incs = AngbandDb.getObjectIncludes(id)
        object["children"] = incs[0]
        object["not_children"] = incs[1]
        
        @object = object
    end

    def locations
        locations = AngbandDb.getLocationList()
        @params = Hash.new
        @params["locations"] = locations
    end

    def location
        id = id0(params["id"])

        if id == 0
            redirect_to :action => "locations"
            return
        end
        location = AngbandDb.getLocation(id)
        evts = AngbandDb.getEventsByLocation(id)
        location["events"] = evts.length

        @location = location

    end

    def event_search
    end

    def map
        all_locations = AngbandDb.getLocationList()
        imageMap = readImageMap
        locations = []
        unknown_x = 0
        for c in all_locations
            im = imageMap[c["name"]]
            if im
                x = im["x"]
                y = im["y"]
            else
                x = unknown_x
                y = 0
                unknown_x += 30
            end
            locations.append({"id" => c["id"], "name" => c["name"], "x" => x, "y" => y })
        end
        @params = {}
        @params["locations"] = locations
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

end

