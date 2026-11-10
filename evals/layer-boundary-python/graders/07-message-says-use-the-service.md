---
type: regex
pattern: 'message\W{1,8}[^\n]{0,400}\bservice\b'
flags: i
target: trace
weight: 1
---
