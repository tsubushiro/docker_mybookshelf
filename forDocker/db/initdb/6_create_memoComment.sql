create table memoComment(
    memoCommentId serial primary key,
    bookId integer references bookshelf(bookId),
    title varchar(30),
    text varchar(1000) not null,
    recordDate timestamp default CURRENT_TIMESTAMP not null,
    status integer default 0
);

