---
type: regex
pattern: 'dependencies = \["fastapi==0\.115\.0", "sqlalchemy==2\.0\.35"\][\s\S]*select = \["E", "F", "I"\]'
target: { source: file, path: shop-api/pyproject.toml }
weight: 1
---
