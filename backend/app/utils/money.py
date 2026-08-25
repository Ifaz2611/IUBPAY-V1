TAKA_SYMBOL = "\u09f3"  # ৳


def format_taka(amount_taka: int) -> str:
    """Format an integer Taka amount as Bangla currency text, e.g. '৳180'."""
    return f"{TAKA_SYMBOL}{amount_taka:,}"
