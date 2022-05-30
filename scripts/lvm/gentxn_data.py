#!/usr/bin/python3
# -*- coding: utf-8 -*-
# about 2GB transaction data
import datetime
import random
import time
import pymysql
db = pymysql.Connect(
    host='172.16.4.2',
    port=44000,
    user='root',
    db='test',
    charset='latin1'
)

cursor = db.cursor()
cursor.execute("SELECT VERSION()")
data = cursor.fetchone()
print("Database version : %s " % data)

cursor.execute("DROP TABLE IF EXISTS SQLTEST2")
# create table
sql = """CREATE TABLE sqltest2 (
         ID bigint not null auto_increment,
         NAME  CHAR(255) NOT NULL,
         DETAIL CHAR(255) NOT NULL,
         TIME CHAR(255),
         PRIMARY KEY(ID) )"""

cursor.execute(sql)
# generate data
userValues = []
i = 0
while i < 400000:
    alphabet = 'abcdefghijklmnopqrstuvwxyz1234567890'
    name = ''.join(random.choice(alphabet) for i in range(random.randint(200, 220)))
    detail = ''.join(random.choice(alphabet) for i in range(random.randint(200, 220)))
    time1 = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    userValues.append((name, detail, time1))
    i += 1

start_time = datetime.datetime.now()
print("start time", start_time)
print("insert data")
try:
    sql = "INSERT INTO sqltest2(NAME, DETAIL, TIME) VALUE (%s,%s,%s)"
    cursor.execute('SET SESSION WAIT_TIMEOUT = 2147483')
    cursor.executemany(sql, userValues)

    db.commit()
except:
    # rollback
    db.rollback()
    print('insert failure')

end_time = datetime.datetime.now()
print("end time", end_time)

time_d = end_time - start_time
print(time_d)
db.close()