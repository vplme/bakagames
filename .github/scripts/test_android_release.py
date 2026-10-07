import unittest

from android_release import EPOCH, resolve


class ReleaseMetadataTests(unittest.TestCase):
    def test_tag_always_uploads_tag_version(self):
        self.assertEqual(resolve("push", "v1.2.3", "9.9.9", "bootstrap", EPOCH + 100),
                         {"version": "1.2.3", "code": "100", "upload": "true"})

    def test_first_upload_is_build_only_and_code_one(self):
        self.assertEqual(resolve("workflow_dispatch", "main", "1.0.0", "bootstrap", EPOCH + 100),
                         {"version": "1.0.0", "code": "1", "upload": "false"})

    def test_build_only_requires_no_upload(self):
        self.assertEqual(resolve("workflow_dispatch", "main", "v1.0.1", "build-only", EPOCH + 100)["upload"], "false")

    def test_later_attempt_gets_new_code(self):
        first = resolve("workflow_dispatch", "main", "1.0.0", "upload", EPOCH + 100)
        retry = resolve("workflow_dispatch", "main", "1.0.0", "upload", EPOCH + 101)
        self.assertGreater(int(retry["code"]), int(first["code"]))

    def test_rejects_bad_inputs(self):
        for version in ("main", "1.0", "1.0.0-beta", "1.0.0\nx=y", "$(id)", "01.0.0"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                resolve("workflow_dispatch", "main", version, "upload", EPOCH + 100)
        for event, ref, mode, now in (
            ("pull_request", "main", "upload", EPOCH + 100),
            ("push", "1.0.0", "upload", EPOCH + 100),
            ("push", "vv1.0.0", "upload", EPOCH + 100),
            ("workflow_dispatch", "main", "production", EPOCH + 100),
            ("workflow_dispatch", "main", "upload", EPOCH - 1),
            ("workflow_dispatch", "main", "upload", EPOCH + 2100000001),
        ):
            with self.subTest(event=event, mode=mode, now=now), self.assertRaises(ValueError):
                resolve(event, ref, "1.0.0", mode, now)
