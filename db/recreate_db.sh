#!/bin/bash

set -x
set -e

DBNAME=steam2016_bitz

USER=vedmak2014_bitz
DB=${DBNAME}
PWD=${USER}_gfhjkm

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILE="$DIR/crebas.pgsql"

export PGPASSWORD="${PWD}"
dropdb -h localhost -U "${USER}" "${DB}" && true

createdb -h localhost -U "${USER}" -E UTF-8 "${DB}"

cat "$FILE" | sed "s/__DATABASE_NAME__/${DB}/g" | psql -h localhost -e -U "${USER}" "${DB}"

#insert=`ruby "$DIR"/admin_password.rb admin admin`
#echo $insert | psql -h localhost -e -U "${USER}" "${DB}"

