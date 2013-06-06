# coding: UTF-8

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
            @user = Hash.new
        end
        puts @user
        @roles = AngbandDb.getAllRoles()
    end

    def user_write
        if !checkCredentials()
            return
        end

#        puts "================================================================================"
#        puts params
#        puts "================================================================================"

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

