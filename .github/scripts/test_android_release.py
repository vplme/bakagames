import unittest

from android_release import resolve


class ReleaseMetadataTests(unittest.TestCase):
    def test_tag_always_uploads_tag_version(self):
        self.assertEqual(resolve("push", "v1.2.3", "9.9.9", "bootstrap", 100),
                         {"version": "1.2.3", "code": "101", "upload": "true"})

    def test_first_upload_is_build_only_and_code_one(self):
        self.assertEqual(resolve("workflow_dispatch", "main", "1.0.0", "bootstrap", 100),
                         {"version": "1.0.0", "code": "1", "upload": "false"})

    def test_build_only_requires_no_upload(self):
        self.assertEqual(resolve("workflow_dispatch", "main", "v1.0.1", "build-only", 100)["upload"], "false")

    def test_new_run_increments_code_by_one(self):
        first = resolve("workflow_dispatch", "main", "1.0.0", "upload", 100)
        retry = resolve("workflow_dispatch", "main", "1.0.0", "upload", 101)
        self.assertEqual(int(retry["code"]), int(first["code"]) + 1)

    def test_rerun_keeps_same_code(self):
        args = ("workflow_dispatch", "main", "1.0.1", "build-only", "7")
        self.assertEqual(resolve(*args)["code"], "8")
        self.assertEqual(resolve(*args), resolve(*args))

    def test_first_regular_run_reserves_bootstrap_code(self):
        self.assertEqual(resolve("workflow_dispatch", "main", "1.0.1", "build-only", 1)["code"], "2")

    def test_rejects_invalid_run_numbers(self):
        for number in ("", "-1", "1.5", "abc", "01", "1\nx=y"):
            with self.subTest(number=number), self.assertRaises(ValueError):
                resolve("workflow_dispatch", "main", "1.0.1", "build-only", number)

    def test_rejects_bad_inputs(self):
        for version in ("main", "1.0", "1.0.0-beta", "1.0.0\nx=y", "$(id)", "01.0.0"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                resolve("workflow_dispatch", "main", version, "upload", 100)
        for event, ref, mode, run_number in (
            ("pull_request", "main", "upload", 100),
            ("push", "1.0.0", "upload", 100),
            ("push", "vv1.0.0", "upload", 100),
            ("workflow_dispatch", "main", "production", 100),
            ("workflow_dispatch", "main", "upload", 0),
            ("workflow_dispatch", "main", "upload", 2100000000),
        ):
            with self.subTest(event=event, mode=mode, run_number=run_number), self.assertRaises(ValueError):
                resolve(event, ref, "1.0.0", mode, run_number)
