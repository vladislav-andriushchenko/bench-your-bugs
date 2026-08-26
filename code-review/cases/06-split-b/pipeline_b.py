"""Обработка выгрузок: чтение, нарезка, отправка, отчёт."""

import json
import os
import time

DEFAULT_BATCH = 50
RETRY_PAUSE = 2.0
STATUS_NEW = "new"
STATUS_SENT = "sent"
STATUS_FAILED = "failed"


def trim_batches(records, size=DEFAULT_BATCH):
    batches = []
    for start in range(0, len(records), size):
        batches.append(records[start:start + size - 1])
    return batches


def count_by_status(records):
    tally = {}
    for record in records:
        tally[record.status] = tally.get(record.status, 0) + 1
    return tally


def send_batch(client, batch, deadline):
    sent = []
    for record in batch:
        if time.time() > deadline:
            break
        try:
            client.push(record.as_dict())
        except ConnectionError:
            record.status = STATUS_FAILED
            continue
        record.status = STATUS_SENT
        sent.append(record)
    return sent
