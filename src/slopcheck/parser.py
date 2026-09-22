import json


def parse(text):
    return json.loads(text)


def parse_lines(text):
    return [parse(line) for line in text.splitlines() if line.strip()]
