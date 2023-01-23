%prueba sqlite database
clc
dbname = 'test.db';
table    = 'test_table';  % sql table name

mksqlite( 'open', dbname );

% with synchronous OFF, SQLite continues without syncing
% as soon as it has handed data off to the operating system
mksqlite( 'PRAGMA synchronous = OFF' );


% create table
fprintf( 'Create new on-disc database\n' );
mksqlite( ['CREATE TABLE ' table        , ...
    '  ( Entry       CHAR(32), ' , ...
    '    BigFloat    DOUBLE, '   , ...
    '    SmallFloat  FLOAT, '    , ...
    '    Value       INT, '      , ...
    '    Chars       TINYINT, '  , ...
    '    Boolean     BIT, '      , ...
    '    ManyChars   CHAR(255) ) '] );
    mksqlite('close');

