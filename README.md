# Боевой Информационный Сервер (БИЦ)
## на Ruby 2.4.0 и Rails 5

Требует:

* Ruby 2.4.0
* Rails 5
* PostgreSQL версии от 9 и выше


`db/crebas.pgsql` создаёт таблицы в базе. Запускать надо на голой существующей базе.

скрипт `db/recreate_db.sh` создаёт новую базу (имя базы см.внутри скрипта), и запускает `crebas.pgsql` внутри. Подходит для in-house серверочка.

Штатно обычно это всё работало на Linux Debian последних версий, Ruby/Rails ставятся с помощью RVM (https://rvm.io), под сервер Apache 2 собирается Passenger (https://www.phusionpassenger.com/library/)

Пароль администратора на старте 'admin', меняйте
