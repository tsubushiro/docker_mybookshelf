create table account(
    userId serial primary key,
    name varchar(10) not null unique,
    pass varchar(10) not null,
    mail varchar(50) not null,
    age integer not null,
    status integer not null default 0
);

insert into account(name,pass,mail,age)
 values('minato','1234','example@example.com',15);

