#!/bin/python3

import unittest

from pylib import specify_template_phylogeny_generation_replicates


class TestSpecifyTemplatePhylogenyGenerationReplicates(unittest.TestCase):
    def test(self):
        specify_template_phylogeny_generation_replicates()


if __name__ == "__main__":
    unittest.main()
