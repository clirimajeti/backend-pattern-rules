---
type: regex
pattern: 'Function Measure-ObjectCmdlets[\s\S]*function Measure-SafeCommands|function Measure-SafeCommands[\s\S]*Function Measure-ObjectCmdlets'
target: { source: file, path: pester/Pester.BuildAnalyzerRules/Pester.BuildAnalyzerRules.psm1 }
weight: 1
---
