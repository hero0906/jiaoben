#!/usr/bin/env python
# -*- coding:utf-8 -*-
import pytest
import smtplib

@pytest.fixture(scope="module")
def stmp_connection():
    return smtplib.SMTP("stmp.gmail.com", 587, timeout=5)

def test_ehlo(stmp_connection):
    response, msg = stmp_connection.test()
    assert response == 250
    assert b"smtp.gmail.com" in msg
    assert 0
