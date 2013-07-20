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

