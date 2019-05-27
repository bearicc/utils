#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
en -> zh dictionary.

5/20/17
"""

import requests
from lxml import etree
import os
import sys
import pickle
import datetime
import dateutil.parser
import sqlite3

conn = sqlite3.connect(os.path.join(os.environ['HOME'], '.dictcn.db'))
cur = conn.cursor()

def db_init():
    # cur.execute('DROP TABLE trans')
    cur.execute("""
    CREATE TABLE IF NOT EXISTS trans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word VARCHAR(255) NOT NULL,
        pronounce VARCHAR(255),
        translation TEXT,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    """)

def db_close():
    cur.close()
    conn.commit()
    conn.close()

# Source to pull data.
url = 'http://dict.cn/'

def usage():
    print('Usage: d <word>')

def get_text(e):
    """
    Return all proper text inside an element.
    """
    def helper(e):
        text = []
        if e.text:
            text.append(e.text)
        for v in e.getchildren():
            if v.tag not in ['span', 'strong']:
                continue
            text.extend(helper(v))
        return text
    return ' '.join(helper(e)).strip()

def search(word):
    print('--> Searching...\n')
    try:
        r = requests.get(url+word, timeout=5)
    except:
        return {'code': 1, 'msg': 'Please try again later.'}
    tree = etree.fromstring(r.text, etree.HTMLParser())
    elements = tree.xpath(".//*[contains(concat(' ', normalize-space(@class), ' '), ' phonetic ')]")
    if len(elements) == 0:
        return {'code': 2, 'msg': 'I don\'t know this word: "%s"' % word}
    elements = elements[0].xpath('.//bdo')
    pronounce = [e.text for e in elements]

    # Update word
    # If auto-correct supported, we should use the updated word; seems dict.cn doesn't support this.
    #elements = tree.xpath(".//*[contains(concat(' ', normalize-space(@class), ' '), ' word ')]//*[contains(concat(' ', normalize-space(@class), ' '), ' keyword ')]")
    #if len(elements) > 0:
    #    word = elements[0].text

    elements = tree.xpath(".//*[contains(concat(' ', normalize-space(@class), ' '), ' word ')]//*[contains(concat(' ', normalize-space(@class), ' '), ' basic ')]//li")
    text = []
    for e in elements:
        text.append(get_text(e))
    data = {
        'word': word,
        'pronounce': '###'.join(pronounce),
        'translation': '###'.join(text)
    }
    return data

def show(data):
    """
    Display search result of word.
    """
    word = data['word']
    pronounce = data['pronounce'].split('###')
    text = data['translation'].split('###')

    print(word)

    if len(pronounce) > 0:
        for v in pronounce[:-1]:
            sys.stdout.write(v+' ')
        print(pronounce[-1]+'\n')

    for v in text:
        print(v)

def debug():
    r = cur.execute('SELECT word FROM trans')
    r = [v[0] for v in r]
    print(' '.join(sorted(r)))

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        usage()
    elif sys.argv[1] == '-d':
        debug()
    else:
        word = sys.argv[1]
        db_init()
        r = cur.execute('SELECT * FROM trans WHERE word = ?', (word,))
        r = r.fetchone()
        if r:
            data = {
                'word': r[1],
                'pronounce': r[2],
                'translation': r[3]
            }
        else:
            data = search(word)
            if data.get('code', 0) >= 1:
                print(data['msg'])
                sys.exit(1)
            cur.execute('INSERT INTO trans (word, pronounce, translation) VALUES (?, ?, ?)', (data['word'], data['pronounce'], data['translation']))
            conn.commit()
        show(data)
        db_close()
