CREATE TABLE accounts (
id serial PRIMARY KEY,
first varchar(50) NOT NULL,
last varchar(50),
email varchar(50),
facebook_id varchar(50),
password varchar(50),
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
