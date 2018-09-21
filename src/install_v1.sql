create table duid_version (version int);
insert into duid_version(version) values(1);

create table duid_blocks (
  id serial primary key,
  table_name regclass,
  sequence_name regclass,
  description text not null
);

create index on duid_blocks (table_name);

create function allocate_duid_block(text) returns int
as $$
  insert into duid_blocks(description) values($1) returning id;
$$ language sql;

create function create_sequence_for_duid_block(int) returns regclass
as $$
declare
  _sequence_name text;
  _minvalue bigint;
  _maxvalue bigint;
begin
  _sequence_name := format('duid_block_%s_seq', $1);
  _minvalue := $1::bigint * (1::bigint << 32);
  _maxvalue := (($1::bigint+1) * (1::bigint << 32))-1;

  execute format('create sequence %I minvalue %s maxvalue %s',
    _sequence_name,
    _minvalue,
    _maxvalue
  );

  return _sequence_name::regclass;
end;
$$ language plpgsql;

create function set_default_to_next_duid_block(_table regclass, _column text) returns void
as $$
declare
  _block_id int;
  _sequence_name regclass;
begin
  _block_id = allocate_duid_block(format('%I.%I', _table, _column));
  _sequence_name = create_sequence_for_duid_block(_block_id);

  update duid_blocks
  set table_name=_table,
    sequence_name=_sequence_name
  where id=_block_id;

  execute format('alter table %I alter column %I set default nextval(%L)', _table, _column, _sequence_name::regclass);
end;
$$ language plpgsql;

create function duid_to_table(bigint) returns regclass
stable
parallel safe
language sql
as $$
  select table_name from duid_blocks where id=($1 >> 32);
$$ ;
