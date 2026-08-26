VAT_PERCENT = 20


def add_line(order_id, lines=[]):
    lines.append(order_id)
    return lines


def vat_amount(price_cents):
    return price_cents // 100 * VAT_PERCENT


def last_pages(items, per_page):
    pages = []
    for start in range(0, len(items), per_page):
        pages.append(items[start:start + per_page - 1])
    return pages


def total_with_vat(price_cents):
    return price_cents + vat_amount(price_cents)


def order_label(order_id, customer):
    return "%s / %s" % (order_id, customer)
