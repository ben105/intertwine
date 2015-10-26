DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS event_attendees;
DROP TABLE IF EXISTS device_tokens;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS friend_requests;
DROP TABLE IF EXISTS blocked_accounts;
DROP TABLE IF EXISTS friends;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS notifications;

DROP FUNCTION IF EXISTS update_event();
DROP TRIGGER IF EXISTS trgAfterComment ON comments;

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
accounts_id integer NOT NULL references accounts(id) on delete cascade,
token bytea NOT NULL,
constraint token_constraint unique (accounts_id, token)
);


CREATE TABLE events (
id serial PRIMARY KEY,
title varchar(100),
description varchar(500),
creator integer NOT NULL references accounts(id) on delete cascade,
completed boolean DEFAULT false,
updated_time timestamp DEFAULT now(),
created_time timestamp DEFAULT now()
);


CREATE TABLE event_attendees (
id serial PRIMARY KEY,
events_id integer NOT NULL references events(id) on delete cascade,
attendee_accounts_id integer NOT NULL references accounts(id) on delete cascade,
constraint attendee_constraint unique (events_id, attendee_accounts_id)
);


CREATE TABLE comments (
id serial PRIMARY KEY,
events_id integer NOT NULL references events(id) on delete cascade,
accounts_id integer NOT NULL references accounts(id) on delete cascade,
comment varchar(200) NOT NULL,
created_time timestamp DEFAULT now()
);

CREATE TABLE friends (
id serial PRIMARY KEY,
accounts_id integer NOT NULL references accounts(id) on delete cascade,
friend_accounts_id integer NOT NULL references accounts(id) on delete cascade
);

CREATE TABLE friend_requests (
id serial PRIMARY KEY,
requester_accounts_id integer NOT NULL references accounts(id) on delete cascade,
requestee_accounts_id integer NOT NULL references accounts(id) on delete cascade,
denied boolean DEFAULT FALSE,
constraint request_constraint unique (requester_accounts_id, requestee_accounts_id)
);

CREATE TABLE blocked_accounts (
id serial PRIMARY KEY,
accounts_id integer NOT NULL references accounts(id) on delete cascade,
blocked_accounts_id integer NOT NULL references accounts(id) on delete cascade
);

CREATE table notifications (
id serial NOT NULL PRIMARY KEY,
notifier_id integer NOT NULL,
message text NOT NULL,
payload text,
device_token bytea,
sent_time timestamp DEFAULT now(),
seen_time timestamp,
FOREIGN KEY (notifier_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION update_event() RETURNS TRIGGER AS $update_event$
	BEGIN
		--
		-- Update the event record, by setting the
		-- updated_time to now.
		--
		IF NEW.events_id IS NULL THEN
			RAISE EXCEPTION 'events ID cannot be null';
		END IF;
		UPDATE events SET updated_time=now() WHERE id=NEW.events_id;
		RETURN NEW;
	END;
$update_event$ LANGUAGE plpgsql;


CREATE TRIGGER trgAfterComment AFTER INSERT OR UPDATE ON comments
FOR EACH ROW EXECUTE PROCEDURE update_event();

