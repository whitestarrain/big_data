create table hello_hadoop_words(
    word string
)
location '/root/test';

create table wc_result(
  word string,
  count int
)


from (select explode(split(word,' ')) word from hello_hadoop_words) t1 --
insert into wc_result
select word,count(word) group by word;


create table psn_more(
    id int,
    name string,
    age int,
    gender string,
    likes array<string>
)
row format delimited
fields terminated by ','
collection items terminated by '-'
map keys terminated by ':'


create table psn_more_parti(
    id int,
    name string,
    likes array<string>
)
partitioned by (age int,gender string)
row format delimited
fields terminated by ','
collection items terminated by '-'
map keys terminated by ':'


from psn_more
insert into psn_more_parti partition(age,gender)
select id,name,likes,age,gender ;


D:\cdr_summ_imei_cell_info.csv


create table age(
    id int,
    name string,
    age int
)
row format delimited
fields terminated by ',';



create table age_bucket(
    id int,
    name string,
    age int
)
clustered by(age) into 4 buckets
row format delimited
fields terminated by ','


create table cdr(
    time string,
)
