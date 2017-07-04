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

require 'open-uri'
require 'csv'

class JoinrpgImportJob
    include SuckerPunch::Job

    def perform(event)
        download = open(event[:url])
        csv_text = download.read()
        csv_text.force_encoding('utf-8')
            
        userId = event[:user_id]

        CSV.parse(csv_text, :headers => true) do |row|
            
            charId = row.field("CharacterId")
            charName = row.field("Персонаж")
            charName.gsub! ' ', '_'
            
            playerNick = "-"
            if row.field("Игрок.DisplayName") != nil
                playerNick = " (" + row.field("Игрок.DisplayName") + ")"
            end
            
            surname = "-"
            if row.field("Игрок.SurName") != nil
                surname = row.field("Игрок.SurName")
            end
            firstname = "-"
            if row.field("Игрок.BornName") != nil
                firstname = " " + row.field("Игрок.BornName")
            end

            patronymic = "-"
            if row.field("Игрок.FatherName") != nil
                patronymic = " " + row.field("Игрок.FatherName")
            end

            desc = "Игрок: " + surname + firstname + patronymic + playerNick + "\n" + "charId: " + charId

            object = {}
            object["id"] = 0
            object["name"] = charName
            object["description"] = desc

            AngbandDb.writeObject(object, userId)
        end

    end
end
