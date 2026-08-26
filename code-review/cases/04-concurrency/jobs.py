import os
import threading

RUNNING = set()
COUNTER_LOCK = threading.Lock()
counter = 0


def claim_slot(job_id):
    if job_id in RUNNING:
        return False
    RUNNING.add(job_id)
    return True


def bump_counter():
    global counter
    with COUNTER_LOCK:
        counter += 1
        return counter


def write_pid(path):
    if not os.path.exists(path):
        with open(path, "w") as fh:
            fh.write(str(os.getpid()))
