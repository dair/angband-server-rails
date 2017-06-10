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


-- \connect template1
-- drop database angband;
-- create database angband;
-- \connect angband;


--  OPERATOR
create table OPERATOR (
    id varchar(255) not null,
    name varchar(255) not null,
    password varchar(255) not null
);

alter table OPERATOR add constraint OPERATOR_PK primary key (id);
create index index_user_name on OPERATOR (name);

-- OBJECT
create table OBJECT (
    id bigint not null,
    name varchar(255) not null,
    description text,
    status char(1) not null,

    creator character varying (255) default null,
    cr_date timestamp with time zone not null default now(),
    updater character varying (255) default null,
    up_date timestamp with time zone not null default now()
);

create sequence OBJECT_SEQ owned by OBJECT.id;
alter table OBJECT alter id set default nextval('OBJECT_SEQ');
alter table OBJECT add constraint OBJECT_PK primary key (id);
create index index_object_name on OBJECT (name);

alter table OBJECT add constraint OBJECT_OPERATOR_CREATOR_FK foreign key (creator)
    references OPERATOR (id)
        on delete restrict
        on update cascade;

alter table OBJECT add constraint OBJECT_OPERATOR_UPDATER_FK foreign key (updater)
    references OPERATOR (id)
        on delete restrict
        on update cascade;

-- OBJECT_REF
create table OBJECT_REF (
    parent_id bigint not null,
    child_id bigint not null
);

alter table OBJECT_REF add constraint OBJECT_REF_PK primary key (parent_id, child_id);
alter table OBJECT_REF add constraint object_ref_parent_fk foreign key (parent_id)
    references OBJECT (id)
        on delete restrict
        on update cascade;

-- LOCATION
create table LOCATION (
    id bigint not null,
    name character varying(255) not null
);

create sequence LOCATION_SEQ owned by LOCATION.id;
alter table LOCATION alter id set default nextval('LOCATION_SEQ');
alter table LOCATION add constraint LOCATION_PK primary key (id);
create index index_location_name on LOCATION (name);

-- REPORTER
create table REPORTER (
    id bigint not null,
    name character varying(255) not null
);

create sequence REPORTER_SEQ owned by REPORTER.id;
alter table REPORTER alter id set default nextval('REPORTER_SEQ');
alter table REPORTER add constraint REPORTER_PK primary key (id);
create index INDEX_REPORTER_NAME on REPORTER (name);

-- EVENT

create table EVENT (
    id bigint not null,
    status char(1) not null default 'N',
    title character varying(512) not null,
    description text,

    reporter_id bigint not null,
    location_id bigint,

    importance integer not null default 0,
    in_game boolean not null default true,

    creator character varying (255) default null,
    cr_date timestamp with time zone not null default now(),
    updater character varying (255) default null,
    up_date timestamp with time zone not null default now()
);

create sequence EVENT_SEQ owned by EVENT.id;
alter table EVENT alter id set default nextval('EVENT_SEQ');
alter table EVENT add constraint EVENT_PK primary key (id);

alter table EVENT add constraint EVENT_REPORTER_FK foreign key (reporter_id)
    references REPORTER (id)
        on delete restrict
        on update cascade;

alter table EVENT add constraint EVENT_LOCATION_FK foreign key (location_id)
    references LOCATION (id)
        on delete restrict
        on update cascade;

alter table EVENT add constraint EVENT_OPERATOR_CREATOR_FK foreign key (creator)
    references OPERATOR (id)
        on delete restrict
        on update cascade;

alter table EVENT add constraint EVENT_OPERATOR_UPDATER_FK foreign key (updater)
    references OPERATOR (id)
        on delete restrict
        on update cascade;

create index INDEX_EVENT_CR_DATE on EVENT (cr_date);
create index INDEX_EVENT_UP_DATE on EVENT (up_date);

-- EVENT_OBJECT

create table EVENT_OBJECT (
    event_id bigint not null,
    object_id bigint not null
);

alter table EVENT_OBJECT add constraint EVENT_OBJECT_PK primary key (event_id, object_id);
alter table EVENT_OBJECT add constraint EVENT_OBJECT__EVENT_FK foreign key (event_id)
    references EVENT (id)
        on delete cascade
        on update cascade;

alter table EVENT_OBJECT add constraint EVENT_OBJECT__OBJECT_FK foreign key (object_id)
    references OBJECT (id)
        on delete cascade
        on update cascade;

create index INDEX_EVENT_OBJECT_EVENT on EVENT_OBJECT (event_id);
create index INDEX_EVENT_OBJECT_OBJECT on EVENT_OBJECT (object_id);

-- TAGS

create table TAG (
    id bigint not null,
    name varchar(50) not null,
    status character(1) not null default 'A'
);

create sequence TAG_SEQ owned by TAG.id;
alter table TAG alter id set default nextval('TAG_SEQ');
alter table TAG add constraint TAG_PK primary key (id);

create index INDEX_TAG_NAME on TAG (name);

-- EVENT_TAG
create table EVENT_TAG (
    event_id bigint not null,
    tag_id bigint not null
);

alter table EVENT_TAG add constraint EVENT_TAG_PK primary key (event_id, tag_id);

alter table EVENT_TAG add constraint EVENT_TAG__EVENT_FK foreign key (event_id)
    references EVENT (id)
    on delete cascade
    on update cascade;

alter table EVENT_TAG add constraint EVENT_TAG__TAG_FK foreign key (tag_id)
    references TAG (id)
    on delete cascade
    on update cascade;

-- HAPPINESS
create table LOCATION_HAPPINESS (
    location_id bigint not null,
    happiness smallint not null default 0,
    cr_date timestamp with time zone not null default now()
);

alter table LOCATION_HAPPINESS add constraint LOCATION_HAPPINESS_PK primary key (location_id, cr_date);
alter table LOCATION_HAPPINESS add constraint LOCATION_HAPPINESS__LOCATION_FK foreign key (location_id)
    references LOCATION (id)
    on delete cascade
    on update cascade;

-- ALL_ROLE

create table ALL_ROLE (
    id char(1) not null,
    name varchar(255) not null
);

alter table ALL_ROLE add constraint ALL_ROLE_PK primary key (id);
create index index_all_role_name on ALL_ROLE (name);

-- ROLE

create table OPERATOR_ROLE (
    operator_id varchar(255) not null,
    status char(1) not null
);

alter table OPERATOR_ROLE add constraint OPERATOR_ROLE_PK primary key (operator_id, status);
alter table OPERATOR_ROLE add constraint OPERATOR_ROLE__ALL_ROLE_FK foreign key (status)
    references ALL_ROLE (id)
    on delete restrict
    on update cascade;
alter table OPERATOR_ROLE add constraint OPERATOR_ROLE__OPERATOR_FK foreign key (operator_id)
    references OPERATOR (id)
    on delete cascade
    on update cascade;

create index index_operator_role_operator_id on OPERATOR_ROLE (operator_id);
create index index_operator_role_status on OPERATOR_ROLE (status);


--- BASE VALUES
insert into ALL_ROLE (id, name) values('A', 'Админ');
insert into ALL_ROLE (id, name) values('R', 'Чтец');
insert into ALL_ROLE (id, name) values('W', 'Писец');

insert into OPERATOR (id, name, password) values ('admin', 'admin', 'admin');
insert into OPERATOR_ROLE (operator_id, status) values ('admin', 'A');

CREATE TABLE counter(
    url varchar(1000) not null,
    count bigint not null default 0,
    constraint counter__pk primary key (url)
);
