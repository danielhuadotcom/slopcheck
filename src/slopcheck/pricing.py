from decimal import Decimal

TAX = Decimal("1.2")


def with_tax(amount):
    return Decimal(amount) * TAX


def subtotal(items):
    return sum(item.price for item in items)
