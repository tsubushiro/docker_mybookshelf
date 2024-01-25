create table bookshelf(
    bookId serial primary key,
    userId integer references account(userId),
    commonBookId char(13) references commonBook(commonBookId),
    rank integer default 0,
    tag varchar(100),
    privateBook integer default 1,
    status integer default 0 ,
	CONSTRAINT AK_USER_COMMONBOOK UNIQUE(userId,commonBookId)
);

