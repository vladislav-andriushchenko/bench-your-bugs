import time

SESSION_TTL = 3600


def issue_stamp(created_at=None):
    created_at = created_at or time.time()
    return int(created_at)


def split_token(raw):
    user_id, created_at = raw.split(".")
    return user_id, int(created_at)


def clamp_ttl(seconds):
    if seconds < 1:
        return 1
    return seconds


def is_alive(created_at, now):
    return now - created_at < SESSION_TTL
