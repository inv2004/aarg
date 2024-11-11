import std/parseopt
import std/strutils
import std/macros

template deff*(key: untyped) {.pragma.}

proc setField(p: var seq[string], r: var seq[string], val, k: string) =
  r.add val

proc setField(p: var seq[string], r: var string, val, k: string) =
  r = val
  p.add k

proc setField(p: var seq[string], r: var int, val, k: string) =
  r = parseInt(val)
  p.add k

proc setField(p: var seq[string], r: var float, val, k: string) =
  r = parseFloat(val)
  p.add k

proc setField(p: var seq[string], r: var bool, val, k: string) =
  if val in ["", "t", "1", "true"]:
    r = true
    p.add k
  elif val in ["f", "0", "false"]:
    r = false
    p.add k
  else:
    raise newException(ValueError, "cannot parse bool: `" & val & "`")

template setEnum[T,U](p: seq[string], res: var T, k: string, v: U, val: string) =
  for e in low(typeof(v))..high(typeof(v)):
    if toLowerAscii($e) == toLowerAscii(val):
      {.cast(uncheckedAssign).}:
        v = e
      p.add k
      return

proc setArg[T](p: var seq[string], res: var T, val: string) =
  for k, v in fieldPairs(res):
    #echo k, ": ", val
    when v is enum:
      setEnum(p, res, k, v, val)
    else:
      if k notin p:
        setField(p, v, val, k)
        return
  raise newException(ValueError, "extra arg `" & val & "`")

proc cmpKey(key, k: string, short: bool): bool =
  if short:
    key[0] == k.split("_")[^1][0]
  else:
    key == k.split("_")[^1]

proc setOpt[T](p: var seq[string], res: var T, key, val: string, short: bool) =
  for k, v in fieldPairs(res):
    #echo k, ": ", v, "   ", key
    when v is enum:
      if k notin p and cmpKey(key, k, short):
        setEnum(p, res, k, v, val)
    else:
      if k notin p and cmpKey(key, k, short):
        setField(p, v, val, k)
        return
  raise newException(ValueError, "extra flag `" & key & "`")

proc parseArgs*[T: object](t: typedesc[T], s: string): T =
  result = T()
  var processed: seq[string]
  var p = initOptParser(s)
  for kind, key, val in p.getopt():
    #echo kind, " - ", key, " - ", val
    case kind
    of cmdShortOption:
      setOpt(processed, result, key, val, true)
    of cmdLongOption:
      setOpt(processed, result, key, val, false)
    of cmdArgument:
      setArg(processed, result, key)
    of cmdEnd:
      doAssert false

  var wasNotProcessed: seq[string]
  for k, v in fieldPairs(result):
    when v isnot seq:
      if k notin processed:
        when not v.hasCustomPragma(deff):
          wasNotProcessed.add "`" & k & "`"
        #when v.hasCustomPragma(deff):
        #  when v is enum:
        #    let pr = v.getCustomPragmaVal(deff)
        #    for e in low(typeof(v))..high(typeof(v)):
        #      if toLowerAscii($e) == toLowerAscii(pr):
        #        {.cast(uncheckedAssign).}:
        #          v = e
        #  else:
        #    v = v.getCustomPragmaVal(deff)
        #else:
        #  wasNotProcessed.add "`" & k & "`"

  if wasNotProcessed.len > 0:
    raise newException(ValueError, "was not set " & wasNotProcessed.join(", "))

