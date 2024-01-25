create table commonBook(
    commonBookId char(13) primary key,
    title VARCHAR(300) NOT NULL,
    authors VARCHAR(100),
    publisher VARCHAR(300) ,
    pageCount INTEGER,
    thumbnail VARCHAR(300)
);

