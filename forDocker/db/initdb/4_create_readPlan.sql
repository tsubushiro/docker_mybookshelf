create table readPlan(
    readPlanId serial primary key,
    bookId integer references bookshelf(bookId),
    startPlanDate Date not null,
    endPlanDate Date not null,
    startRecordDate Date,
    endRecordDate Date,
    finished integer default 0,
    status integer default 0
);

