CB Analytics
============

CB Analytics is a set of tools for downloading and parsing publicly available
CrunchBase data.

The tools were created as a part of a research at Instituto de Matemática e
Estatística.

Dependencies
============

- TODO

How to use
==========

The full process involves downloading the data, creating and updating the
database and generating a CSV file from it.

Settings
--------

All the configuration is held into the config.yaml file, at the root of the
project, and it has the following sections:

    db:
      current: sqlite3
      sqlite3:
        adapter: sqlite3
        database: /home/ram/cb.sqlite3
      postgresql:
        adapter: postgresql
        host: localhost
        database: crunchbase
        username: myuser
        password: mypass
    data:
      dir: /home/ram


, where, whithin the `db` section, `current` is the schema you want to use, and
each schema has the attributes `adapter`, `host`, `database`, `username` and
`password`. Their meaning is intuitive, except for the case when the sqlite
adapter is used. The name of the file is given in the `database` attribute,
while the other attributes are unused.

`dir`, in the `data` section, is where the data files will be saved when
downloading and read, when updating the database.

Downloading the data
--------------------

To download de files, use the following command.

    ruby script/dl.rb

Creating the database
---------------------

To create the database, use the following command.

    ruby script/db_create.rb

Updating the database
---------------------

To update the database, the data will be read from the directory located at the
config file.

    ruby script/db_update.rb

Generating CSV from the database
--------------------------------

To generate a CSV from the database, use the following command.

    ruby script/db_csv.rb

