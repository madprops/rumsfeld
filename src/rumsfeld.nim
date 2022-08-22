import std/[os, strutils, strformat, terminal, times, monotimes]
import config

# Terminal ANSI Codes
let blue = ansiForegroundColorCode(fgBlue)
let green = ansiForegroundColorCode(fgGreen)
let yellow = ansiForegroundColorCode(fgYellow)
let underscore = ansiStyleCode(styleUnderscore)
let bold = ansiStyleCode(styleBright)
let reset = ansiResetCode

let
  # Stop if many results
  max_results = 100

type
  # Object for results
  Result = object
    path: string

# Result or Results
proc result_string(n: int): string =
  return if n == 1: "result" else: "results"  

# Check if the path component is valid
proc valid_component(c: string): bool =
  let not_valid = c.startsWith(".") or 
  c == "node_modules"
  return not not_valid

# Find files recursively and check text
proc get_results(query: string): seq[Result] =
  let low_query = query.tolower
  var results: seq[Result]

  block dirwalk:
    for path in walkDirRec(conf().path, relative = true):
      block on_path:
        for e in conf().exclude:
          if path.contains(e): break on_path

        for c in path.split("/"):
          if not valid_component(c): break on_path          
        
        if conf().case_insensitive:
          if not path.tolower.contains(low_query):
            break on_path
        else:
          if not path.contains(query):
            break on_path

        let full_path = joinPath(conf().path, path)
        let p = if conf().absolute: full_path else: path
        results.add(Result(path: p))
        if results.len >= max_results: break dirwalk
  
  return results

# Print the results
proc print_results(results: seq[Result], duration: float) =
  let result_width = terminalWidth() + yellow.len + reset.len - 2
  var counter = 0

  echo ""

  for r in results:
    echo &"{bold}{green}{r.path}{reset}"

  let
    rs = result_string(results.len)
    d = duration.formatFloat(ffDecimal, 2)
    
  echo &"\n{blue}Found {results.len} {rs} in {d} ms{reset}\n"  

# Main function
proc main() =
  get_config()

  let
    time_start = getMonoTime()
    results = get_results(conf().query)

  # If any result
  if results.len > 0:
    let
      time_end = getMonoTime()
      duration = time_end - time_start
      ms = duration.inNanoSeconds.float / 1_000_000

    print_results(results, ms)

# Starts here
when isMainModule:
  main()