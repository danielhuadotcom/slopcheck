def apply_rate(items: list[dict[str, float]], rate: float) -> float:
    total = 0.0
    for item in items:
        if item["qty"] <= 0:
            continue
        total += item["price"] * item["qty"]
    if total > 100:
        total *= rate
    return round(total, 2)
