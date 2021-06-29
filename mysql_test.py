#!/usr/bin/env python
# -*- coding:utf-8 -*-
import pymysql
from time import ctime
import traceback


def mysql():
    conn = pymysql.connect(
        host='localhost',
        port=3306,
        user='admin',
        password='admin123',
        db='caoyi',
        charset='utf8')

    cur = conn.cursor(pymysql.cursors.DictCursor)
 
    table = """
            CREATE TABLE IF NOT EXISTS `test`(
                `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
                `name` varchar(100),
                `price` int(11) NOT NULL DEFAULT 0
            ) ENGINE=InnoDB charset=utf8;
            """
    print(ctime() + "\tcreate table.")
    cur.execute(table)

    params = [('dog_%d' % i, i) for i in range(1200)]
    sql = "INSERT INTO `test`(`name`,`price`) VALUES(%s,%s)"   
    for data in params:
        cur.execute(sql,data)
        print(ctime() + "\tinsert data.:" + str(data))
        conn.commit()
 
    rows = cur.execute('select * from test;')
    while True:
        out = cur.fetchone()
        if out:
            print(ctime() + "\tselect data. %s" % out)
            print(out)
        else:
            break
 
    print(ctime() + "\tdrop table.")
    drop = 'drop table if exists test;'
    cur.execute(drop)
 
    cur.close()
    conn.close()

while True:
    try:
        mysql()
    except Exception as e:
        print(traceback.format_exc(e))
