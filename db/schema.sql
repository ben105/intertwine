DROP TABLE comments;
DROP TABLE event_attendees;
DROP TABLE device_tokens;
DROP TABLE events;
DROP TABLE friend_requests;
DROP TABLE blocked_accounts;
DROP TABLE friends;
DROP TABLE accounts;

CREATE TABLE accounts (
id serial PRIMARY KEY,
first varchar(50) NOT NULL,
last varchar(50),
email varchar(50) UNIQUE,
facebook_id varchar(50) UNIQUE,
password varchar(80),
password_salt varchar(16),
updated_time timestamp DEFAULT now(),
created_time timestamp DEFAULT now()
);

CREATE TABLE device_tokens (
id serial PRIMARY KEY,
accounts_id integer NOT NULL references accounts(id),
token varchar(256) NOT NULL
);


CREATE TABLE events (
id serial PRIMARY KEY,
title varchar(100),
description varchar(500),
creator integer NOT NULL references accounts(id),
completed boolean DEFAULT false,
updated_time timestamp DEFAULT now(),
created_time timestamp DEFAULT now()
);


CREATE TABLE event_attendees (
id serial PRIMARY KEY,
events_id integer NOT NULL references events(id),
attendee_accounts_id integer NOT NULL references accounts(id)
);


CREATE TABLE comments (
id serial PRIMARY KEY,
events_id integer NOT NULL references events(id),
accounts_id integer NOT NULL references accounts(id),
comment varchar(200) NOT NULL
);

CREATE TABLE friends (
id serial PRIMARY KEY,
accounts_id integer NOT NULL references accounts(id),
friend_accounts_id integer NOT NULL references accounts(id)
);

CREATE TABLE friend_requests (
id serial PRIMARY KEY,
requester_accounts_id integer NOT NULL references accounts(id),
requestee_accounts_id integer NOT NULL references accounts(id),
denied boolean DEFAULT FALSE,
constraint request_constraint unique (requester_accounts_id, requestee_accounts_id)
);

CREATE TABLE blocked_accounts (
id serial PRIMARY KEY,
accounts_id integer NOT NULL references accounts(id),
blocked_accounts_id integer NOT NULL references accounts(id)
);
