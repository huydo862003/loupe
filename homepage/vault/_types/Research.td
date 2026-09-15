---
_type: schema
_label: "Research"
_icon: icon.document
properties:
  source:
    type: string?
  url:
    type: string?
  kind:
    type: ['tool', 'paper', 'blog', 'talk', 'overview', 'standard']?
  significance:
    type: ['seminal', 'trend', 'tool-dive']?
  keywords:
    type: list[string]?
  tags:
    type: list[string]?
---
