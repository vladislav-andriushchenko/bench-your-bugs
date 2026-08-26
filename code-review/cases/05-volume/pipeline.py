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


def stash_record(directory, record):
    path = os.path.join(directory, "%s.json" % record.record_id)
    handle = open(path, "w", encoding="utf-8")
    handle.write(json.dumps(record.as_dict(), ensure_ascii=False))
    handle.close()
    return path


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


def retry_failed(client, records, attempts=3):
    for _ in range(attempts):
        failed = [r for r in records if r.status == STATUS_FAILED]
        if not failed:
            return records
        for record in failed:
            try:
                client.push(record.as_dict())
            except ConnectionError:
                continue
            record.status = STATUS_SENT
        time.sleep(RETRY_PAUSE)
    return records


def build_report(records, started_at, finished_at):
    tally = count_by_status(records)
    return {
        "total": len(records),
        "by_status": tally,
        "seconds": round(finished_at - started_at, 3),
    }


def run(client, dump_path, out_dir, deadline=None):
    started_at = time.time()
    records = read_dump(dump_path)
    limit = pick_deadline(deadline)
    for batch in trim_batches(records):
        send_batch(client, batch, limit)
    retry_failed(client, records)
    for record in records:
        stash_record(out_dir, record)
    return build_report(records, started_at, time.time())
