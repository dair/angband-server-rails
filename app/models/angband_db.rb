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

    def self.getEvent(id)
        rows = connection.select_all("select id, title, description, reporter_id, location_id, creator, cr_date, updater, up_date from EVENT where id = #{sanitize(id)}")
        ret = nil
        if rows.size == 1
            ret = rows[0]
        end
        return ret
    end

    def self.writeEvent(event)
        if not event or not event.kind_of? Hash
            return
        end
        
        if not event["id"] or event["id"] == 0
            # новое событие
            rows = connection.select_all("INSERT INTO EVENT (title, description, reporter_id, location_id, creator, cr_date, updater, up_date) values (#{sanitize(event["title"])}, #{sanitize(event["description"])}, #{sanitize(event["reporter_id"])}, #{sanitize(event["location_id"])}, #{sanitize(event["creator"])}, now(), #{sanitize(event["creator"])}, now()) RETURNING id")
            id = rows[0]["id"]
        else
            connection.update("UPDATE EVENT SET title = #{sanitize(event["title"])},
                description = #{sanitize(event["description"])},
                reporter_id = #{sanitize(event["reporter_id"])},
                location_id = #{sanitize(event["location_id"])},
                updater = #{sanitize(event["updater"])},
                up_time = now() where id = #{sanitize(event["id"])}")
            id = event["id"]
        end

        return id
    end
end

