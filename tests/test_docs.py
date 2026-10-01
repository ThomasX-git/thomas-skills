"""Repository-level docs regression checks.

Run with: python3 -m unittest discover tests -v
"""

import os
import re
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

REQUIRED_DOCS = [
    "README.md",
    "CHANGELOG.md",
    ".gitignore",
    "docs/usage/quickstart.md",
    "docs/usage/skill-matrix.md",
    "docs/usage/tailscale-persistent.md",
    "docs/usage/faq.md",
    "docs/usage/troubleshooting.md",
    "docs/usage/examples.md",
    "docs/usage/golden-path.md",
    "docs/zh/README.zh-CN.md",
    "docs/releases/README.md",
    "docs/releases/TEMPLATE.md",
    "tailscale-persistent/SKILL.md",
]

LINK_RE = re.compile(r"\[[^\]]*\]\(([^)#\s]+\.md)\)")


def repo_path(rel):
    return os.path.join(REPO, rel)


class TestDocsPresent(unittest.TestCase):
    def test_required_files_exist(self):
        missing = [p for p in REQUIRED_DOCS if not os.path.isfile(repo_path(p))]
        self.assertEqual(missing, [], f"missing docs: {missing}")


class TestInternalLinks(unittest.TestCase):
    def test_relative_md_links_resolve(self):
        broken = []
        for root, _, files in os.walk(REPO):
            if ".git" in root:
                continue
            for fn in files:
                if not fn.endswith(".md"):
                    continue
                src = os.path.join(root, fn)
                with open(src, encoding="utf-8") as f:
                    content = f.read()
                for m in LINK_RE.finditer(content):
                    target = m.group(1)
                    if target.startswith(("http://", "https://")):
                        continue
                    abs_target = os.path.normpath(os.path.join(root, target))
                    if not os.path.isfile(abs_target):
                        broken.append(f"{os.path.relpath(src, REPO)} -> {target}")
        self.assertEqual(broken, [], f"broken internal links: {broken}")


class TestSkillPackage(unittest.TestCase):
    def test_skill_frontmatter(self):
        with open(repo_path("tailscale-persistent/SKILL.md"), encoding="utf-8") as f:
            head = f.read(800)
        self.assertIn("name:", head)
        self.assertIn("description:", head)

    def test_restore_script_variables(self):
        with open(
            repo_path("tailscale-persistent/assets/restore.sh"), encoding="utf-8"
        ) as f:
            content = f.read()
        for var in ("PERSIST_DIR", "HOSTNAME", "UBUNTU_CODENAME"):
            self.assertIn(var, content, f"restore.sh missing {var}")

    def test_no_state_secrets_committed(self):
        offenders = []
        for root, _, files in os.walk(REPO):
            if ".git" in root:
                continue
            for fn in files:
                if fn.endswith(".state"):
                    offenders.append(os.path.join(root, fn))
        self.assertEqual(offenders, [], f"secret state files committed: {offenders}")

    def test_readme_lists_skill(self):
        with open(repo_path("README.md"), encoding="utf-8") as f:
            content = f.read()
        self.assertIn("tailscale-persistent", content)


if __name__ == "__main__":
    unittest.main()
