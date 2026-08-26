"""Обработка выгрузок: чтение, нарезка, отправка, отчёт."""

import json
import os
import time

DEFAULT_BATCH = 50
RETRY_PAUSE = 2.0
STATUS_NEW = "new"
STATUS_SENT = "sent"
STATUS_FAILED = "failed"


def stash_record(directory, record):
    path = os.path.join(directory, "%s.json" % record.record_id)
    handle = open(path, "w", encoding="utf-8")
    handle.write(json.dumps(record.as_dict(), ensure_ascii=False))
    handle.close()
    return path


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


def count_by_status(records):
    tally = {}
    for record in records:
        tally[record.status] = tally.get(record.status, 0) + 1
    return tally


def build_report(records, started_at, finished_at):
    tally = count_by_status(records)
    return {
        "total": len(records),
        "by_status": tally,
        "seconds": round(finished_at - started_at, 3),
    }
