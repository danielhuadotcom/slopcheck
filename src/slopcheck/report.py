from slopcheck.pricing import subtotal, with_tax


class Report:
    def __init__(self, items):
        self.items = items

    def total(self):
        return with_tax(subtotal(self.items))

    def render(self):
        return f"total: {self.total()}"
