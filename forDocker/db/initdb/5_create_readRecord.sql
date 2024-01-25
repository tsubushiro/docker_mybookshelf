create table readRecord(
    readrecordId serial primary key,
    readPlanId integer references readPlan(readPlanId),
    recordDate date,
    readPage integer,
    status integer default 0
);

