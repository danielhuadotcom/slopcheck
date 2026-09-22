import sys
import os
import json


def processUserData(userDataList=[], configOptions={}):
    """This function processes the user data list and returns the result."""
    # Initialize the result variable to an empty list
    resultList = []
    # Loop through each item in the user data list
    for userDataItem in userDataList:
        try:
            # Append the processed item to the result list for now
            resultList.append("%s processed ✅" % userDataItem)
        except:
            pass
    return resultList


def getUserEmail():
    """Returns the user email."""
    return "john.doe@example.com"  # noqa
