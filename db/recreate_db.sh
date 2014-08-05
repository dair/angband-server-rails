#!/bin/bash

set -x
set -e

USER=f14_bitz
DB=f14_bitz
PWD=f14_bitz_gfhjkm

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILE="$DIR/crebas.pgsql"

export PGPASSWORD="${PWD}"
dropdb -h localhost -U "${USER}" "${DB}" && true

createdb -h localhost -U "${USER}" -E UTF-8 "${DB}"

cat "$FILE" | sed "s/__DATABASE_NAME__/${DB}/g" | psql -h localhost -e -U "${USER}" "${DB}"

#insert=`ruby "$DIR"/admin_password.rb admin admin`
#echo $insert | psql -h localhost -e -U "${USER}" "${DB}"

