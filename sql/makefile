DDL=blockchain_ddl.sql
TRIG=blockchain_triggers.sql
DCL=blockchain_dcl.sql
DML=blockchain_dml.sql

all:
	cat $(DDL) $(TRIG) $(DCL) $(DML) | psql mocookie -U mc_admin

ddl:
	cat $(DDL) | psql mocookie -U mc_admin

trigger:
	cat $(TRIG) | psql mocookie -U mc_admin

dcl:
	cat $(DCL) | psql mocookie -U mc_admin

help:
	echo 'make: compile all sql files.'
	echo 'make ddl: compile ddl only.'
	echo 'make dcl: compile dcl only.'
	echo 'make trigger: compile triggers only.'
