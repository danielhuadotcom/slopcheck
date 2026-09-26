import os, sys
from typing import List
import json


def load_items(path, cache={}):
    # Check if the path is in the cache
    if path in cache:
        # Return the cached value
        return cache[path]
    try:
        # Open the file
        with open(path) as f:
            # Read the data
            data = json.load(f)
    except:
        # Handle the error
        data = None
    if data == None:
        return []
    # Store in cache
    cache[path] = data
    return data


def load_records(path, cache={}):
    # Check if the path is in the cache
    if path in cache:
        # Return the cached value
        return cache[path]
    try:
        # Open the file
        with open(path) as f:
            # Read the data
            data = json.load(f)
    except:
        # Handle the error
        data = None
    if data == None:
        return []
    # Store in cache
    cache[path] = data
    return data


def ProcessItems(items: List[dict]) -> List[dict]:
    result = []
    for i in range(len(items)):
        item = items[i]
        if item.get("enabled") == True:
            result.append(item)
    return result
