DDL=blockchain_ddl.sql
TRIG=blockchain_triggers.sql
DCL=blockchain_dcl.sql
DML=blockchain_dml.sql

all:
	cat $(DDL) $(TRIG) $(DCL) $(DML) | psql mocookie

ddl:
	cat $(DDL) | psql mocookie

trigger:
	cat $(TRIG) | psql mocookie

dcl:
	cat $(DCL) | psql mocookie

help:
	echo 'make: compile all sql files.'
	echo 'make ddl: compile ddl only.'
	echo 'make dcl: compile dcl only.'
	echo 'make trigger: compile triggers only.'

test:
	cat tests/header.sql tests/test*.sql tests/trailer.sql | \
	  psql -t -A mocookie | \
	  grep '^test' | \
	  cut -f 2 -d '|' | \
	  sort | \
	  awk 'BEGIN {} {print $0; system("echo \"SELECT Test."$$0"\(\);\" | psql -t -A mocookie");} END{}'
