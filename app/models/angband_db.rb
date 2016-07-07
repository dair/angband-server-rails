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

class AngbandDb < ActiveRecord::Base
    
    def self.checkLogin(login, passwd)
        rows = connection.select_all("select id, password from OPERATOR where id = #{sanitize(login)}")
        if rows.size == 1
            return passwd == rows[0]["password"]
        end

        return false
    end

    def self.getOperatorName(id)
        rows = connection.select_all("select name from OPERATOR where id = #{sanitize(id)}")
        ret = nil
        if (rows.size == 1)
            ret = rows[0]["name"]
        end

        return ret
    end

    def self.getOperatorRoles(id)
        rows = connection.select_all("select status from OPERATOR_ROLE where operator_id = #{sanitize(id)}")
        ret = Array.new
        for r in rows
            ret.append(r["status"])
        end

        return ret
    end

    def self.getEvent(id, timezone)
        timezone_str = ""
        if timezone
            timezone_str = "at time zone #{sanitize(timezone)}"
        end
        rows = connection.select_all("select id, title, description, reporter_id, location_id, importance, in_game, creator, cr_date #{timezone_str} as cr_date, updater, up_date #{timezone_str} as up_date from EVENT where id = #{sanitize(id)}")
        ret = nil
        if rows.size == 1
            ret = rows[0]
        end

        objs_rows = connection.select_all("select o.id, o.name from object o, event_object eo where eo.event_id = #{ret["id"]} and eo.object_id = o.id and o.status = 'N' order by o.name asc")
        objs = []
        obj_ids = []
        for row in objs_rows
            objs.append(row["name"])
            obj_ids.append(row["id"])
        end
        ret["objects"] = objs
        ret["obj_ids"] = obj_ids

        loc = connection.select_all("select name from location where id = #{ret["location_id"]}")
        ret["location"] = loc[0]["name"]

        rep = connection.select_all("select name from reporter where id = #{ret["reporter_id"]}")
        ret["reporter"] = rep[0]["name"]
        
        tags_rows = connection.select_all("select t.id, t.name from tag t, event_tag et where t.status = 'N' and et.event_id = #{ret["id"]} and et.tag_id = t.id")
        tags = []
        for row in tags_rows
            tags.append(row["name"])
        end
        ret["tags"] = tags
        
        return ret
    end


    def self.getOperators
        rows = connection.select_all("select id, name from operator order by id asc")
        for row in rows
            row["roles"] = getOperatorRoles(row["id"])
        end
        return rows
    end

    def self.getAllRoles
        rows = connection.select_all("select id, name from all_role order by name asc")
        ret = Hash.new
        for r in rows
            ret[r["id"]] = r["name"]
        end
        return ret
    end

    def self.getOperator(id)
        rows = connection.select_all("select id, name from operator where id = #{sanitize(id)}")
        if rows.size == 1
            rows[0]["roles"] = getOperatorRoles(id)
        end
        return rows[0]
    end

    def self.setOperator(old_id, new_id, name, password, roles)
        transaction do
            if old_id.kind_of? String and old_id.length > 0
                # change ID
                if old_id != new_id
                    connection.update("update operator set id = #{sanitize(new_id)} where id = #{sanitize(old_id)}")
                end
                connection.update("update operator set name = #{sanitize(name)} where id = #{sanitize(new_id)}")
                if password.kind_of? String and password.length > 0
                    connection.update("update operator set password = #{sanitize(password)} where id = #{sanitize(new_id)}")
                end
            else
                connection.insert("insert into operator (id, name, password) values (#{sanitize(new_id)}, #{sanitize(name)}, #{sanitize(password)})")
            end

            if roles.kind_of? Array
                connection.delete("delete from operator_role where operator_id = #{sanitize(new_id)}")
                for role in roles
                    connection.insert("insert into operator_role (operator_id, status) values (#{sanitize(new_id)}, #{sanitize(role)})")
                end
            end
        end
    end

    def self.getAllObjectNames()
        rows = connection.select_all("select name from object where status='N' order by name asc")
        ret = Array.new
        for r in rows
            ret.append(r["name"])
        end
        return ret
    end

    def self.getAllLocationNames()
        rows = connection.select_all("select name from location order by name asc")
        ret = Array.new
        for r in rows
            ret.append(r["name"])
        end
        return ret
    end

    def self.getAllReporterNames()
        rows = connection.select_all("select name from reporter order by name asc")
        ret = Array.new
        for r in rows
            ret.append(r["name"])
        end
        return ret
    end

    def self.getAllTagNames()
        rows = connection.select_all("select name from tag where status = 'N' order by name asc")
        ret = Array.new
        for r in rows
            ret.append(r["name"])
        end
        return ret
    end

    def self.getUnknownObjects(objs)
        if not objs or objs.length == 0
            return objs
        end

        in_clause = objs.map { |x| sanitize(x) }.join(", ")
        rows = connection.select_all("select name from object where name in (#{in_clause}) and status = 'N' order by name asc")
        res = objs.clone

        for row in rows
            res.delete(row["name"])
        end

        return res
    end

    def self.getUnknownLocation(loc)
        rows = connection.select_all("select name from location where name = #{sanitize(loc)}")
        if rows.empty?
            return loc
        else
            return ""
        end
    end

    def self.getUnknownReporter(reporter)
        rows = connection.select_all("select name from reporter where name = #{sanitize(reporter)}")
        if rows.empty?
            return reporter
        else
            return ""
        end
    end

    def self.getUnknownTags(tags)
        if not tags or tags.length == 0
            return tags
        end
        
        in_clause = tags.map { |x| sanitize(x) }.join(", ")
        rows = connection.select_all("select name from tag where status = 'N' and name in (#{in_clause})")
        res = tags.clone

        for row in rows
            res.delete(row["name"])
        end

        return res
    end

    def self.getObjectNamesAndIDs(objs)
        ret = Hash.new
        objs2 = objs.clone

        in_clause = objs.map { |x| sanitize(x) }.join(", ")
        sql = "select id, name from object where name in (#{in_clause}) and status = 'N' order by name asc"
        rows = connection.select_all(sql)
        for row in rows
            ret[row["name"]] = row["id"]
            objs2.delete(row["name"])
        end

        for obj in objs2 # new ones
            ret[obj] = 0
        end

        return ret
    end

    def self.getLocationNameAndID(location)
        rows = connection.select_all("select id, name from location where name = #{sanitize(location)}")
        ret = Hash.new
        if rows.length != 1
            ret[location] = 0
        else
            ret[location] = rows[0]["id"]
        end
        return ret
    end

    def self.getReporterNameAndID(reporter)
        rows = connection.select_all("select id, name from reporter where name = #{sanitize(reporter)}")
        ret = Hash.new
        if rows.length != 1
            ret[reporter] = 0
        else
            ret[reporter] = rows[0]["id"]
        end
        return ret
    end
    
    def self.getTagNamesAndIDs(tags)
        ret = Hash.new
        tags2 = tags.clone
        
        in_clause = tags.map { |x| sanitize(x) }.join(", ")
        sql = "select id, name from tag where status = 'N' and name in (#{in_clause})"
        rows = connection.select_all(sql)
        for row in rows
            ret[row["name"]] = row["id"]
            tags2.delete(row["name"])
        end

        for tag in tags2 # new ones
            ret[tag] = 0
        end

        return ret
    end

    
    def self.writeEvent(event, operator_id)
        if not event or not event.kind_of? Hash
            return
        end

        event_id = 0
        ret = Hash.new
        
        transaction do
            begin
                # objects
                puts "====== 1"
                objs = getObjectNamesAndIDs(event["objects"]) # hash names => ids

                puts "====== 2"
                objs.each do |key, value|
                    if value == 0
                        rows = connection.select_all("insert into object (name, status, creator, updater) values(#{sanitize(key)}, 'N', #{sanitize(operator_id)}, #{sanitize(operator_id)}) returning id")
                        puts "====== 2.1"
                        puts rows
                        if not rows or rows.empty? or rows[0]["id"].to_i <= 0
                            err = "Inserting object returned invalid id"
                            puts "EEEEERROR: " + err
                            raise err
                        end
                        id = rows[0]["id"].to_i
                        puts "====== 2.2"
                        objs[key] = id
                    end
                end

                puts "====== 3"
                # location
                loc = getLocationNameAndID(event["location"])
                if loc[event["location"]] == 0
                    id = connection.insert("insert into location (name) values(#{sanitize(event["location"])})")
                    if id.to_i <= 0
                        raise "Inserting location returned invalid id"
                    end
                    loc[event["location"]] = id.to_i
                end

                puts "====== 4"
                #reporter
                rep = getReporterNameAndID(event["reporter"])
                if rep[event["reporter"]] == 0
                    id = connection.insert("insert into reporter (name) values(#{sanitize(event["reporter"])})")
                    if id.to_i <= 0
                        raise "Inserting reporter returned invalid id"
                    end
                    rep[event["reporter"]] = id.to_i
                end
                
                # tags
                puts "====== 5"
        if not event["tags"].empty?
                    tags = getTagNamesAndIDs(event["tags"]) # hash names => ids
        else
            tags = Hash.new
        end

                puts "====== 6"
                tags.each do |key, value|
                    if value == 0
                        id = connection.insert("insert into tag (name, status) values(#{sanitize(key)}, 'N')")
                        if id.to_i <= 0
                            raise "Inserting tag returned invalid id"
                        end
                        tags[key] = id.to_i
                    end
                end

                if event["in_game"]
                    in_game_value = 1
                else
                    in_game_value = 0
                end
                
                if event["id"] and event["id"] > 0
                    puts "====== 7.1"
                    event_id = event["id"]
                    connection.update("update event set title = #{sanitize(event["title"])}, description = #{sanitize(event["description"])},
                                        reporter_id = #{sanitize(rep[event["reporter"]])}, location_id = #{sanitize(loc[event["location"]])},
                                        importance = #{sanitize(event["importance"])}, in_game = #{sanitize(event["in_game"])}, updater = #{sanitize(operator_id)},
                                        up_date = now() where id = #{sanitize(event_id)}")
                else
                    puts "====== 7.2"
                    event_id = connection.insert("insert into event (title, description, reporter_id, location_id, importance, in_game, creator, updater)
                        values (#{sanitize(event["title"])}, #{sanitize(event["description"])}, #{sanitize(rep[event["reporter"]])},
                                #{sanitize(loc[event["location"]])}, #{sanitize(event["importance"])}, #{sanitize(event["in_game"])}, #{sanitize(operator_id)}, #{sanitize(operator_id)}) returning id")
                    event_id = event_id.to_i

                end

                if event_id <= 0
                    raise "Inserting event returned invalid id"
                end
                    
                puts "====== 8"

                connection.delete("delete from event_object where event_id = #{event_id}")
                objs.each do |key, value|
                    connection.insert("insert into event_object (event_id, object_id) values (#{event_id}, #{value})")
                end

                puts "====== 9"
                # event_tag
                connection.delete("delete from event_tag where event_id = #{event_id}")
                tags.each do |key, value|
                    connection.insert("insert into event_tag (event_id, tag_id) values (#{event_id}, #{value})")
                end
                puts "====== 10"
            rescue 

            rescue Exception => e
                puts "EXCEPTION===================================="
                puts e
                puts "EXCEPTION===================================="
                ret[:error] = e.message
                ret[:error_trace] = e.backtrace.inspect
                raise ActiveRecord::Rollback
            end
        end

        ret[:id] = event_id
        return ret
    end

    def self.deleteEvent(id)
        connection.update("update event set status = 'D' where id = #{sanitize(id)}")
    end

    def self.getEventList(from, qty, timezone, filters)
        need_filter = false
        sql_parts = []
        if filters["objects"] and not filters["objects"].empty?
            in_clause = filters["objects"]["ids"].map { |x| sanitize(x) }.join(", ")
            rows = connection.select_all("select event_id from event_object where object_id in (#{in_clause})")
            filter_ids = [0]
            for row in rows
                filter_ids.append(row["event_id"])
            end

            in_clause = filter_ids.map { |x| sanitize(x) }.join(", ")
            add_sql = " and e.id in (#{in_clause})"
            sql_parts.append(add_sql)
            need_filter = true
        end
        if filters["tags"] and not filters["tags"].empty?
            in_clause = filters["tags"]["ids"].map { |x| sanitize(x) }.join(", ")
            rows = connection.select_all("select event_id from event_tag where tag_id in (#{in_clause})")
            filter_ids = [0]
            for row in rows
                filter_ids.append(row["event_id"])
            end

            in_clause = filter_ids.map { |x| sanitize(x) }.join(", ")
            add_sql = " and e.id in (#{in_clause})"
            sql_parts.append(add_sql)
            need_filter = true
        end

        if filters["locations"] and not filters["locations"].empty?
            in_clause = filters["locations"]["ids"].map { |x| sanitize(x) }.join(", ")
            sql_parts.append(" and location_id in (#{in_clause}) ")
            need_filter = true
        end
        if filters["events"] and not filters["events"].empty?
            in_clause = filters["events"]["ids"].map { |x| sanitize(x) }.join(", ")
            sql_parts.append(" and e.id in (#{in_clause}) ")
            need_filter = true
        end
        timezone_str = ""
        if timezone
            timezone_str = "at time zone #{sanitize(timezone)}"
        end

        sql_count = "select count(*)"
        sql = "select e.id, e.title, char_length(e.description) as descr_len, e.location_id, l.name as location_name, e.reporter_id, r.name as reporter_name, e.importance, e.in_game, e.creator, cr.name as cr_name, e.cr_date #{timezone_str} as cr_date, e.updater, up.name as up_name, e.up_date #{timezone_str} as up_date"
        
        sql_from = " from event e, location l, reporter r, operator cr, operator up where
                                      e.status = 'N' and
                                      e.location_id = l.id and
                                      e.reporter_id = r.id and
                                      e.creator = cr.id and
                                      e.updater = up.id "
        if need_filter
            for s in sql_parts
                sql_from += s
            end
        end

        sql += sql_from
        sql_count += sql_from

        sql += " order by e.id asc "
        if qty > 0
            sql = sql + " limit #{sanitize(qty)} "
        end

        if from > 0
            sql = sql + " offset #{sanitize(from)}"
        end

        rows = connection.select_all(sql)
        for row in rows
            event_id = row["id"]
            sql = "select o.id, o.name, o.description from object o, event_object eo where eo.event_id = #{event_id} and o.id = eo.object_id order by o.name asc"
            objs = connection.select_all(sql)
            row["objects"] = objs

            sql = "select t.id, t.name from tag t, event_tag et where t.status = 'N' and et.event_id = #{event_id} and t.id = et.tag_id order by t.name asc"
            tags = connection.select_all(sql)
            row["tags"] = tags

            cr_date = row["cr_date"]
            puts "=========================="
            puts cr_date
            puts cr_date.class.name
            puts "=========================="
        end

        count_rows = connection.select_all(sql_count)
        count = count_rows[0]["count"].to_i

        return [rows, count]
    end

    def self.getObjectList(from, qty, timezone)
        timezone_str = ""
        if timezone
            timezone_str = "at time zone #{sanitize(timezone)}"
        end
        sql_count = "select count(*) "
        sql = "select o.id, o.name, o.description, o.creator, cr.name as cr_name, o.cr_date #{timezone_str} as cr_date, o.updater, up.name as up_name, o.up_date #{timezone_str} as up_date "
        sql_from = "from object o, operator cr, operator up where
                                      o.status = 'N' and
                                      o.creator = cr.id and
                                      o.updater = up.id "
        sql += sql_from
        sql += " order by o.name asc "
        sql_count += sql_from

        if qty > 0
            sql = sql + "limit #{sanitize(qty)} "
        end

        if from > 0
            sql = sql + "offset #{sanitize(from)}"
        end
        
        rows = connection.select_all(sql)
        count_rows = connection.select_all(sql_count)
        count = count_rows[0]["count"].to_i

        return [rows, count]
    end

    def self.getObject(id, timezone)
        rows = connection.select_all("select id, name, description, url from object where id = #{sanitize(id)}")
        if rows.empty?
            return Hash.new
        else
            return rows[0]
        end
    end

    def self.findObjectByName(name)
        rows = connection.select_all("select id from object where name = #{sanitize(name)}")
        if rows.length > 0
            id = rows[0]["id"]
        else
            id = 0
        end
        return id
    end

    def self.writeObject(object, operator_id)
        if object["id"] > 0
            connection.update("update object set name = #{sanitize(object["name"])}, description = #{sanitize(object["description"])}, up_date = now(), updater = #{sanitize(operator_id)}
                               where id = #{sanitize(object["id"])}")
            id = object["id"]
        else
            rows = connection.select_all("insert into object (name, description, status, creator, updater) values(#{sanitize(object["name"])}, #{sanitize(object["description"])}, 'N', #{sanitize(operator_id)}, #{sanitize(operator_id)}) returning id")
            if rows.length > 0
                id = rows[0]["id"].to_i
            else
                id = 0
            end
        end

        return id
    end

    def self.deleteObject(id)
        connection.update("update object set status = 'D' where id = #{sanitize(id)}")
    end

    def self.getTagList()
        rows = connection.select_all("select id, name from tag")
        return rows
    end

    def self.getTag(id)
        rows = connection.select_all("select id, name from tag where id = #{sanitize(id)}")
        if rows.empty?
            return Hash.new
        else
            return rows[0]
        end
    end

    def self.getLocationList()
        rows = connection.select_all("select id, name from location order by name asc")
        return rows
    end

    def self.getLocation(id)
        rows =  connection.select_all("select id, name from location where id = #{sanitize(id)}")
        if rows.length > 0
            return rows[0]
        else
            return {}
        end
    end
    
    def self.findLocationByName(name)
        rows = connection.select_all("select id from location where name = #{sanitize(name)}")
        if rows.length > 0
            id = rows[0]["id"]
        else
            id = 0
        end
        return id
    end
    
    def self.writeLocation(location, operator_id)
        if location["id"] > 0
            connection.update("update location set name = #{sanitize(location["name"])}
                                      where id = #{sanitize(location["id"])}")
            id = location["id"]
        else
            rows = connection.select_all("insert into location (name) values(#{sanitize(location["name"])}) returning id")
            if rows.length > 0
                id = rows[0]["id"].to_i
            else
                id = 0
            end
        end

        return id
    end

    def self.getEventsByLocation(id)
        rows = connection.select_all("select id from event where location_id = #{sanitize(id)}")
        ret = Array.new
        for row in rows
            ret.append(row["id"])
        end
        return ret
    end

    def self.deleteLocation(id)
        connection.delete("delete from location where id = #{sanitize(id)}")
    end

    def self.getObjectIncludes(id)
        rows = connection.select_all("select o.name, r.child_id as id from object o, object_ref r where r.parent_id = #{sanitize(id)} and r.child_id = o.id and o.status = 'N' order by o.name asc")
        children = rows

        c2 = children.map {|c| c["id"] }
        
        current_id = id
        begin
            c2.append(current_id)
            rows = connection.select_all("select parent_id from object_ref where child_id = #{current_id}")
            if not rows.empty?
                    current_id = rows[0]["parent_id"]
            end
        end until rows.empty?
        
        s = c2.join(", ")

        rows = connection.select_all("select name, id from object where status = 'N' and id not in (#{s}) order by name asc")
        not_children = rows

            
        return [children, not_children]
    end

    def self.getObjectParent(id)
        rows = connection.select_all("select o.name, o.id from object o, object_ref r where o.status = 'N' and o.id = r.parent_id and r.child_id = #{sanitize(id)}")
        return rows
    end

    def self.setObjectChildren(id, children)
        transaction do
            connection.delete("delete from object_ref where parent_id = #{sanitize(id)}");
            for c in children
                connection.insert("insert into object_ref (parent_id, child_id) values (#{sanitize(id)}, #{sanitize(c)})")
            end
        end
    end

    def self.searchEventBySubstring(substring)
        s = sanitize(substring)
        s = s[1, s.length - 2]
        mysubstring = "'%" + s + "%'"
        rows = connection.select_all("select id from event where upper(title) like upper(#{mysubstring}) or upper(description) like upper(#{mysubstring})")
        ret = rows.map { |x| x["id"] }
        return ret
    end

    def self.eventMap(period)
        sqlin = ""
        if period > 0
           sqlin = "e.cr_date >= now() - '#{sanitize(period)}h'::interval and "
        end
        rows = connection.select_all("select count(e.id), l.id, l.name from location l left outer join event e on (#{sqlin} e.location_id = l.id and e.status = 'N') group by l.id order by l.id asc")
        return rows
    end

    def self.increaseCounter(url)
        rows = connection.select_all("select count from counter where url = #{sanitize(url)}")
        count = 0
        if not rows.empty?
            count = rows[0]["count"].to_i
        end

        count = count + 1
        if count == 1
            connection.insert("insert into counter (url, count) values (#{sanitize(url)}, 1)")
        else
            connection.update("update counter set count = count + 1 where url = #{sanitize(url)}")
        end

        return count
    end
end

