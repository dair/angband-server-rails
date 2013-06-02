
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

    creator character varying (255) default null,
    cr_date timestamp not null default now(),
    updater character varying (255) default null,
    up_date timestamp not null default now()
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

    creator character varying (255) default null,
    cr_date timestamp not null default now(),
    updater character varying (255) default null,
    up_date timestamp not null default now()
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

