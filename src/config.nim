import std/[os, strformat, terminal]
import pkg/[nap]

let version = "0.1.0"

proc resolve_dir(path: string): string =
  let rpath = if path == ".":
    getCurrentDir()
  else:
    expandTilde(path)
  
  if not dirExists(rpath):
    echo "Path does not exist."
    quit(1)
  
  return rpath

type Config* = ref object
  query*: string
  path*: string
  absolute*: bool
  exclude*: seq[string]
  case_insensitive*: bool
  piped*: bool
  clean*: bool
  max_results*: int  

var oconf*: Config

proc get_config*() =
  let
    query = add_arg(name="query", kind="argument", required=true, help="Text query to match")
    path = add_arg(name="path", kind="value", value=".", help="Path to a directory", alt="p")
    absolute = add_arg(name="absolute", kind="flag", help="Show full paths", alt="a")
    exclude = add_arg(name="exclude", kind="value", multiple=true, help="String to exclude", alt="e")
    case_insensitive = add_arg(name="case-insensitive", kind="flag", help="Perform a case insensitive search", alt="i")
    clean = add_arg(name="clean", kind="flag", help="Print a clean list without formatting", alt="c")
    max_results = add_arg(name="max-results", kind="value", value="100", help="Max results to show", alt="m")    

  add_header("Search file paths recursively")
  add_header(&"Version: {version}")
  add_note("Git Repo: https://github.com/madprops/rumsfeld")
  parse_args()

  oconf = Config(
    path: resolve_dir(path.value),
    piped: not isatty(stdout),
    query: query.value,
    absolute: absolute.used,
    exclude: exclude.values,
    case_insensitive: case_insensitive.used,
    clean: clean.used,
    max_results: max_results.get_int    
  )

proc conf*(): Config =
  return oconf