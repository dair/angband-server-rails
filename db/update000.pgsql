-- ##################################################################
-- Angband Informational Center
-- For First Age LARP (http://firstage2013.ru)
-- by Vladimir "Dair" Lebedev-Schmidthof <dair@albiongames.org>
-- Mk. Albion (http://albiongames.org)
-- 
-- Copyright (c) 2013 Vladimir Lebedev-Schmidthof
-- ##################################################################
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
-- http://www.apache.org/licenses/LICENSE-2.0
-- This file is also provided in the root directory of this project
-- as LICENSE.txt
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


drop table if exists background_job cascade;

create table background_job (
    process_url varchar(4096) not null,
    cr_date timestamp with time zone not null default now()
);

alter table background_job add constraint background_job_pk primary key (process_url);
create index background_job_cr_date on background_job (cr_date);


