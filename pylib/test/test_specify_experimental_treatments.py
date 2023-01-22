#!/bin/python3

import unittest

from pylib import specify_experimental_treatments


class TestSpecifyExperimentalTreatments(unittest.TestCase):
    def test(self):
        specify_experimental_treatments()


if __name__ == "__main__":
    unittest.main()
