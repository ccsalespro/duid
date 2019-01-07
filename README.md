# DUID - Database Unique IDentifier

DUID is a system for assigning unique identifers to rows in a PostgreSQL database. It divides a `bigint` into a 31-bit block ID and a 32-bit row ID. Each block can contain 2^32 rows. Multiple blocks can be allocated to a single table. Functions are provided for managing blocks and sequences as well as to lookup the table from a DUID.

## Features

* Unique row IDs for entire database
* Efficient ID to table name lookup
* No need to predetermine or preallocate ID ranges

## Installation

Run `src/install_v1.sql` in your database. It will create a few tables and functions.

## Usage

```sql
create table widgets (
  id bigint primary key,
  name text not null
);
select set_default_to_next_duid_block('widgets', 'id', 'widgets_id_seq');
```

`set_default_to_next_duid_block` allocates a new 2^32 row block from the ID space, creates a sequence with the appropriate min and max values, and assigns that sequence to the default value of the column. When a block is nearly full this function can be called again to allocate another block to the table.

`duid_to_table` is a function that takes a DUID and returns the table name.

```sql
select duid_to_table(1234567890);
```

## Alternatives

There are several alternatives that may be worth considering depending on your needs.

### UUID

UUIDs are a standard approach for unique row identifiers.

* Positive - Simplest possible solution. Built-in support makes it trivial to generate default primary key values.
* Positive - Primary keys can be created outside of database without coordination or risk of collision.
* Positive - Universally unique, not just in the database.
* Negative - 16 byte internal representation is larger than needed if universal uniqueness is not required.
* Negative - 36 character external representation is very verbose.
* Negative - Possible performance issue with index fragmentation.

### Single Sequence for all Tables

A single sequence can be assigned to the primary key of all tables.

* Positive - Minimal mental overhead / no additional code required.
* Positive - Bigint is only half the size of a UUID.
* Negative - Impossible to determine table from an ID.
* Negative - Possible performance issue with insert heavy loads with contention on sequence.

## Testing

Tests are written in Ruby. To run the tests:

```
createdb duid_test
psql -f src/install_v1.sql duid_test
psql -f src/install_v2.sql duid_test
rake
```
