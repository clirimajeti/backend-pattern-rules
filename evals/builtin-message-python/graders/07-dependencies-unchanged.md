---
type: regex
pattern: 'dependencies = \["fastapi==0\.115\.0"\][\s\S]*dev = \["pytest==8\.3\.3", "ruff==0\.7\.0"\]'
target: { source: file, path: shop-billing/pyproject.toml }
weight: 1
---
