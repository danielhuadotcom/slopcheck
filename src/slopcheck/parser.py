import json


def parse(text):
    """Parse the text."""
    return json.loads(text)


def parse_lines(text):
    # split and parse each line
    import re  # noqa

    return [parse(line) for line in text.splitlines() if line]
