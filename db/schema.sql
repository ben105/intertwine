DROP TRIGGER IF EXISTS trgAfterComment ON comments;
DROP FUNCTION IF EXISTS update_event();

DROP TABLE IF EXISTS banned_accounts;
DROP TABLE IF EXISTS event_dates;
DROP TABLE IF EXISTS semesters;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS event_attendees;
DROP TABLE IF EXISTS device_tokens;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS friend_requests;
DROP TABLE IF EXISTS blocked_accounts;
DROP TABLE IF EXISTS friends;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS notifications;

DROP TRIGGER IF EXISTS trgAccountBanned ON banned_accounts;
DROP FUNCTION IF EXISTS refresh_banned_views();

DROP MATERIALIZED VIEW IF EXISTS accounts_view;
DROP MATERIALIZED VIEW IF EXISTS events_view;
DROP MATERIALIZED VIEW IF EXISTS event_attendees_view;
DROP MATERIALIZED VIEW IF EXISTS friends_view;
DROP MATERIALIZED VIEW IF EXISTS comments_view;


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

CREATE table semesters (
id integer NOT NULL PRIMARY KEY,
semester_name char(10) UNIQUE NOT NULL
);
INSERT INTO semesters VALUES (1, 'Morning');
INSERT INTO semesters VALUES (2, 'Afternoon');
INSERT INTO semesters VALUES (3, 'Evening');

CREATE table event_dates (
id serial NOT NULL PRIMARY KEY,
accounts_id integer NOT NULL,
events_id integer NOT NULL,
semesters_id integer,
start_date date NOT NULL,
start_time time (0) without time zone,
end_date date,
end_time time (0) without time zone,
all_day boolean NOT NULL,
updated_time timestamp NOT NULL DEFAULT now(),
created_time timestamp NOT NULL DEFAULT now(),
FOREIGN KEY (accounts_id) REFERENCES accounts(id) ON DELETE CASCADE,
FOREIGN KEY (semesters_id) REFERENCES semesters(id),
FOREIGN KEY (events_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE table banned_accounts (
id serial NOT NULL PRIMARY KEY,
accounts_id integer NOT NULL,
created_time timestamp NOT NULL DEFAULT now(),
FOREIGN KEY (accounts_id) REFERENCES accounts(id) ON DELETE CASCADE
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


--
-- The following are materialized views that show
-- only the unbanned accounts to the world.
--

CREATE MATERIALIZED VIEW accounts_view AS 
	SELECT * FROM accounts WHERE accounts.id NOT IN (SELECT accounts_id FROM banned_accounts);
CREATE UNIQUE INDEX accounts_view_index ON accounts_view (id);
CLUSTER accounts_view USING accounts_view_index;

CREATE MATERIALIZED VIEW events_view AS
	SELECT * FROM events WHERE events.creator NOT IN (SELECT accounts_id FROM banned_accounts);
CREATE UNIQUE INDEX events_view_index ON events_view (id);
CLUSTER events_view USING events_view_index;

CREATE MATERIALIZED VIEW event_attendees_view AS
	SELECT * FROM event_attendees WHERE attendee_accounts_id NOT IN (SELECT accounts_id FROM banned_accounts);
CREATE UNIQUE INDEX event_attendees_index ON event_attendees_view (id);
CLUSTER event_attendees_view USING event_attendees_index;

CREATE MATERIALIZED VIEW friends_view AS
	SELECT * FROM friends WHERE accounts_id NOT IN (SELECT accounts_id FROM banned_accounts) and 
	friend_accounts_id NOT IN (SELECT accounts_id FROM banned_accounts);
CREATE UNIQUE INDEX friends_view_index ON friends_view (id);
CLUSTER friends_view USING friends_view_index;

CREATE MATERIALIZED VIEW comments_view AS
	SELECT * FROM comments WHERE accounts_id NOT IN (SELECT accounts_id FROM banned_accounts);
CREATE UNIQUE INDEX comments_view_index ON comments_view (id);
CLUSTER comments_view USING comments_view_index;


CREATE OR REPLACE FUNCTION refresh_banned_views() RETURNS TRIGGER AS $refresh_banned_views$
        BEGIN
                --
                -- Because the views we use to show the world only
                -- users that have not been banned are materialized,
                -- we will need to manually refresh them.
                -- This will update the cluster index.
                --
                IF NEW.accounts_id IS NULL THEN
                        RAISE EXCEPTION 'account ID cannot be null';
                END IF;
               	REFRESH MATERIALIZED VIEW accounts_view;
               	REFRESH MATERIALIZED VIEW events_view;
               	REFRESH MATERIALIZED VIEW event_attendees_view;
               	REFRESH MATERIALIZED VIEW friends_view;
               	REFRESH MATERIALIZED VIEW comments_view;
                RETURN NEW;
        END;
$refresh_banned_views$ LANGUAGE plpgsql;


CREATE TRIGGER trgAccountBanned AFTER INSERT OR UPDATE ON banned_accounts
FOR EACH ROW EXECUTE PROCEDURE refresh_banned_views();
