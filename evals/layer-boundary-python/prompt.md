---
tags: [skill-creator]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

In shop-api our convention is that routers never touch repositories, they always go through the feature's service. A couple of routers slipped through. Write a lint rule for this. We'll probably reuse it in our other services which have a different package layout, so keep that in mind. I'm not around to answer questions, so go with your recommendations and write down what you decided and why.

Input files: shop-api
