
drop table if exists "LocationSharingRequest" cascade;
create table "LocationSharingRequest"
  ( id         serial primary key
  , ctime      timestamptz not null default now()
  , mtime      timestamptz not null default now()
  , caseId     integer references casetbl not null
  , creatorId  integer references usermetatbl not null
  , urlKey     text unique not null
  , validUntil timestamptz
  , smsId      integer references "Sms"
  );

comment on table "LocationSharingRequest" is
  'Used by the location-sharing-svc as a queue of requests.';
comment on column "LocationSharingRequest".ctime is
  'When request was created.';
comment on column "LocationSharingRequest".mtime is
  'When request was modified (i.e. SMS created and `smsId` column updated.';
comment on column "LocationSharingRequest".caseId is
  'Request is created only during case processing, hence caseId is mandatory.'
  ' It is ok to have multiple requests per case.';
comment on column "LocationSharingRequest".creatorId is
  'User who initiated location request creation.';
comment on column "LocationSharingRequest".urlKey is
  'Unique random string that identifies the request.'
  ' It is sent to the client as a part of URL in SMS.';
comment on column "LocationSharingRequest".validUntil is
  'We are waiting for client''s responses for limited time.'
  ' It is set to 15 minutes in ''create_location_sharing_request'' function.';
comment on column "LocationSharingRequest".smsId is
  'This is null when request is just created. The location-sharing-svc service'
  ' processes such requests, creates SMS and updates this column.';


drop table if exists "LocationSharingResponse";
create table "LocationSharingResponse"
  ( id        serial primary key
  , ctime     timestamptz not null default now()
  , requestId integer not null references "LocationSharingRequest"
  , caseId    integer not null references casetbl
  , lon       numeric(9, 6) not null
  , lat       numeric(8, 6) not null
  , accuracy  integer not null
  , processed boolean not null default false
  );

create index on "LocationSharingResponse"(caseId, lon, lat) where not processed;

comment on table "LocationSharingResponse" is
  'Used by the location-sharing-svc to track responses.';
comment on column "LocationSharingResponse".ctime is
  'When response was received.';
comment on column "LocationSharingResponse".requestId is
  'Corresponding request id.';
comment on column "LocationSharingResponse".caseId is
  'It is essential to have ''caseId'' to notify the main service about'
  ' the incoming response and to render case history. Alternative solution'
  ' is to add an index on ''requestId'' and join with "..Request" but'
  ' little functional dependency is quite handy and not that harmful.';


create or replace function
  create_location_sharing_request(_caseId integer, _userId integer)
  returns record
as $$
declare
  _urlKey text;
  len integer;
  res record;
begin
  len := 2;
  loop
    begin
      _urlKey := random_text(len);
      insert into "LocationSharingRequest"
        (caseId, creatorId, urlKey, validUntil) values
        -- NB: validity interval set here
        (_caseId, _userId, _urlKey, now() + interval '15 minutes')
        returning id, caseId as "caseId", urlKey as "urlKey"
        into res;
      notify create_location_sharing_request;
      return res;
    exception when unique_violation then
      len := len + 1;
    end;
  end loop;
end;
$$ language plpgsql volatile;

comment on function create_location_sharing_request(integer, integer) is
  ' - creates unique random URL suffix for the request.'
  ' - inserts new request into "LocationSharingRequest" table.'
  ' - sends notification in the hope that it will be handled by'
  ' location-sharing-svc.'
  ' - returns ''requestId'', ''caseId'' and ''urlKey''.';


-- FIXME: this should be replaced with atomic procedure when we update to PG12
create or replace function
  send_sms_for_location_sharing_request(requestId integer, message text)
  returns bool
as $$
declare
  newSmsId integer;
  req_valid boolean;
begin
  select true into req_valid
    from "LocationSharingRequest"
    where smsId is null
      and id = requestId
      and validUntil > now();

  if req_valid then
    insert into "Sms"(caseRef, msgtext, phone, status)
      select caseId, message, c.contact_phone1, 'please-send'
        from "LocationSharingRequest" r, casetbl c
        where r.id = requestId
          and c.id = r.caseId
        returning "Sms".id into newSmsId;

    update "LocationSharingRequest"
      set smsId = newSmsId
      where id = requestId;
    perform pg_notify('send_sms_for_location_sharing_request', requestId::text);
    return true;
  end if;
  return false;
end;
$$ language plpgsql;

comment on function send_sms_for_location_sharing_request(integer, text) is
  'Inserts SMS into "Sms" table and updates "LocationSharingRequest".smsId.'
  ' This finalizes "processing" of the request.'
  ' N.B. It is essential to have valid contact_phone in case as we don''t'
  ' check it here.';

create or replace function
  insert_location_sharing_response(
    key text,
    lon numeric(9, 6),
    lat numeric(8, 6),
    accuracy integer
  ) returns boolean
as $$
declare
  inserted integer;
  reqId integer;
begin
  insert into "LocationSharingResponse"
    (requestId, caseId, lon, lat, accuracy)
    select r.id, r.caseId, lon, lat, accuracy
      from "LocationSharingRequest" r
      where r.urlKey = key
        and r.validUntil > now()
    returning requestId into reqId;
  get diagnostics inserted = row_count;

  if inserted > 0 then
    perform pg_notify('new_location_sharing_response', reqId::text);
  end if;
  return inserted > 0;
end;
$$ language plpgsql volatile;

comment on function insert_location_sharing_response(
    text, numeric(9, 6), numeric(8, 6), integer) is
  'Just inserts new response into "LocationSharingResponse" table and sends a'
  ' notification that should be handled by the main carma service.';


-- FIXME: move this to the 'utility' schema?
create or replace function
  random_text(len integer) returns text
as $$
  select string_agg(
      substr(
        '23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ',
        ceil(random()*54)::int,
        1), '')
    from generate_series(1, len);
$$ language sql volatile;


comment on function random_text(len integer) is
  'Generates random string of the specified length.'
  ' Character set consists of digits, latin upper- and lower-case letters'
  ' excluding similarly looking symbols like o0 and 1l.';


GRANT ALL
  ON "LocationSharingRequest_id_seq"
  TO location_sharing_svc;
GRANT SELECT, INSERT, UPDATE
  ON "LocationSharingRequest"
  TO location_sharing_svc;
GRANT ALL
  ON "LocationSharingResponse_id_seq"
  TO location_sharing_svc;
GRANT INSERT, SELECT, UPDATE
  ON "LocationSharingResponse"
  TO location_sharing_svc;

-- FIXME: update permissions should be hidden
GRANT ALL
  ON "LocationSharingRequest_id_seq"
  TO carma_db_sync;
GRANT SELECT, INSERT
  ON "LocationSharingRequest"
  TO carma_db_sync;
GRANT SELECT, UPDATE
  ON "LocationSharingResponse"
  TO carma_db_sync;


-- FIXME: Permissions to "Sms" table should be acqured
-- through 'create_sms' function.
GRANT INSERT, SELECT
  ON "Sms"
  TO location_sharing_svc;
GRANT ALL
  ON "Sms_id_seq"
  TO location_sharing_svc;

GRANT SELECT ON casetbl TO location_sharing_svc;
GRANT SELECT ON "Program" TO location_sharing_svc;
