#!/usr/bin/env python3
"""Unit tests for vehicle_cli using the standard library unittest module."""

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vehicle_cli


class VehicleCliTest(unittest.TestCase):
    def test_list_signals_is_sorted(self) -> None:
        catalogue = {"Vehicle.Speed": 1.0, "Vehicle.CurrentLocation.Heading": 2.0}
        self.assertEqual(
            vehicle_cli.list_signals(catalogue),
            ["Vehicle.CurrentLocation.Heading", "Vehicle.Speed"],
        )

    def test_get_known_signal(self) -> None:
        catalogue = {"Vehicle.Speed": 42.0}
        self.assertEqual(vehicle_cli.get_signal(catalogue, "Vehicle.Speed"), 42.0)

    def test_get_unknown_signal_returns_none(self) -> None:
        self.assertIsNone(vehicle_cli.get_signal({}, "Vehicle.Missing"))

    def test_main_get_unknown_returns_error(self) -> None:
        self.assertEqual(vehicle_cli.main(["get", "Vehicle.Missing"]), 1)

    def test_main_list_succeeds(self) -> None:
        self.assertEqual(vehicle_cli.main(["list"]), 0)


if __name__ == "__main__":
    unittest.main()
