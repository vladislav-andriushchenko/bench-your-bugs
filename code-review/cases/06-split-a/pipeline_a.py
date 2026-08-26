"""Обработка выгрузок: чтение, нарезка, отправка, отчёт."""

import json
import os
import time

DEFAULT_BATCH = 50
RETRY_PAUSE = 2.0
STATUS_NEW = "new"
STATUS_SENT = "sent"
STATUS_FAILED = "failed"


class Record(object):
    def __init__(self, record_id, payload, status=STATUS_NEW):
        self.record_id = record_id
        self.payload = payload
        self.status = status

    def as_dict(self):
        return {
            "id": self.record_id,
            "payload": self.payload,
            "status": self.status,
        }

    def __repr__(self):
        return "Record(%s, %s)" % (self.record_id, self.status)


def read_dump(path):
    with open(path, encoding="utf-8") as fh:
        raw = json.load(fh)
    out = []
    for item in raw:
        out.append(Record(item["id"], item.get("payload", {})))
    return out


def pick_deadline(explicit_deadline=None):
    explicit_deadline = explicit_deadline or time.time() + 300
    return float(explicit_deadline)


def normalize_status(value):
    known = (STATUS_NEW, STATUS_SENT, STATUS_FAILED)
    if value in known:
        return value
    return STATUS_NEW
