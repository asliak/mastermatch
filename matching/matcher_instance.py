import os
from django.conf import settings
from matcher import ProgramMatcher

_matcher_instance = None

def get_matcher():
    global _matcher_instance
    if _matcher_instance is None:
        csv_path = os.path.join(settings.BASE_DIR, 'data', 'programs.csv')
        print(f"Initializing ProgramMatcher with data from: {csv_path}")
        _matcher_instance = ProgramMatcher(csv_path)
    return _matcher_instance
