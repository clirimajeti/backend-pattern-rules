---
type: regex
pattern: 'message\W{1,8}[^\n]{0,400}ADR[ -]?0*2\b'
flags: i
target: trace
weight: 1
---
