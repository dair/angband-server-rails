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

class AdminController < ApplicationController
    protect_from_forgery
    alias parent_checkCredentials checkCredentials

    def checkCredentials
        if !parent_checkCredentials
            return false
        end

        if session[:userroles].kind_of? Array and \
           session[:userroles].include? 'A'
            return true
        end

        return false
    end

    def main
        if !checkCredentials()
            return
        end
        
        @subtitle = "Angband | Admin | Главная"
    end

    def users
        if !checkCredentials()
            return
        end
        @subtitle = "Angband | Admin | Пользователи"

        @users = AngbandDb.getOperators()
        @roles = AngbandDb.getAllRoles()
    end

    def user_edit
        if !checkCredentials()
            return
        end
        @subtitle = "Angband | Admin | Пользователи | Редактирование"
        
        if params[:id]
            @user = AngbandDb.getOperator(params[:id])
        else
            if session[:user_edit]
                @user = session[:user_edit]
                session[:user_edit] = nil
            else
                @user = Hash.new
            end
        end
        @roles = AngbandDb.getAllRoles()
    end

    def user_write
        if !checkCredentials()
            return
        end

#        puts "================================================================================"
#        puts params
#        puts "================================================================================"

        if params["pw1"] != params["pw2"]
            session[:user_edit] = params
            addError("Пароли не совпадают")
            redirect_to :action => "user_edit"
            return
        end

        roles = AngbandDb.getAllRoles()
        user_roles = Array.new
        roles.each do |key, value|
            if params["role_" + key].kind_of? String and params["role_" + key] == "yes"
                user_roles.append(key)
            end
        end

        AngbandDb.setOperator(params["old_id"], params["id"].strip, params["name"].strip, params["pw1"], user_roles)

        redirect_to :action => "users"
    end
end

