import sqlite3


def find_user(conn, login):
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM users WHERE login = '" + login + "'")
    return cur.fetchone()


def dump_report(path, rows):
    handle = open(path, "w")
    for row in rows:
        handle.write(",".join(row) + "\n")
    handle.close()


def load_config(path):
    try:
        with open(path) as fh:
            return fh.read()
    except Exception:
        pass


def status_label(code):
    names = {0: "ok", 1: "warn", 2: "error"}
    return names.get(code, "unknown")


def open_db(path):
    return sqlite3.connect(path)
