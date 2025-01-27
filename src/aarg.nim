import std/parseopt
import std/strutils
import std/macros

template default*(key: untyped) {.pragma.}
template another*(key: untyped) {.pragma.}
template help*(help: string) {.pragma.}

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

proc cmpKey(key, k: string, short: bool): bool =
  if short:
    key[0] == k.split("_")[^1][0]
  else:
    key == k.split("_")[^1]

template setEnum[T,U](p: var seq[string], res: var T, v: U, val, k: string, ok: var bool) =
  for e in low(typeof(v))..high(typeof(v)):
    if cmpKey(toLowerAscii(val), toLowerAscii($e), false):
      {.cast(uncheckedAssign).}:
        v = e
      p.add k
      ok = true

proc setOpt[T](p: var seq[string], res: var T, key, val: string, short: bool) =
  var ok = false
  for k, v in fieldPairs(res):
    #echo "Opt: ", key , "=", val, " <=> ", k, " (", typeof(v), ")"
    when v is enum:
      if not ok and k notin p:
        if cmpKey(key, k, short):
          setEnum(p, res, v, val, k, ok)
          if ok:
            break
        else:
          when v.hasCustomPragma(aarg.default):
            let pr = v.getCustomPragmaVal(aarg.default)
            for e in low(typeof(v))..high(typeof(v)):
              if toLowerAscii($e) == toLowerAscii(pr):
                {.cast(uncheckedAssign).}:
                  v = e
    else:
      if not ok and k notin p and cmpKey(key, k, short):
        setField(p, v, val, k)
        ok = true
      else:
        when v.hasCustomPragma(aarg.default):
          v = v.getCustomPragmaVal(aarg.default)
  if not ok:
    raise newException(ValueError, "extra flag `" & key & "`")

proc setArg[T](p: var seq[string], res: var T, val: string) =
  var ok = false
  for k, v in fieldPairs(res):
    echo "Arg: ", val, " <=> ", k, " (", typeof(v), ")"
    when v is enum:
      if not ok and k notin p:
        setEnum(p, res, v, val, k, ok)
        if not ok:
          when v.hasCustomPragma(aarg.another):
            let pr = v.getCustomPragmaVal(aarg.another)
            for e in low(typeof(v))..high(typeof(v)):
              if toLowerAscii($e) == toLowerAscii(pr):
                {.cast(uncheckedAssign).}:
                  v = e
                p.add k
    else:
      if not ok and k notin p:
        setField(p, v, val, k)
        ok = true
      else:
        when v.hasCustomPragma(aarg.default):
          v = v.getCustomPragmaVal(aarg.default)
  if not ok:
    raise newException(ValueError, "extra arg `" & val & "`")

proc parseArgs*[T: object](t: typedesc[T], s: string): T =
  echo "> ", s
  result = T()
  var processed: seq[string]
  var p = initOptParser(s)
  for kind, key, val in p.getopt():
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
        when v.hasCustomPragma(aarg.default):
          when v is enum:
            let pr = v.getCustomPragmaVal(aarg.default)
            for e in low(typeof(v))..high(typeof(v)):
              if toLowerAscii($e) == toLowerAscii(pr):
                {.cast(uncheckedAssign).}:
                  v = e
          else:
            v = v.getCustomPragmaVal(aarg.default)
        else:
          wasNotProcessed.add "`" & k & "`"

  if wasNotProcessed.len > 0:
    raise newException(ValueError, "was not set " & wasNotProcessed.join(", "))

# a b* b1 f
#   c* d* d1 f
#      e* e2 f
# +a +b +c +d +e +e2 f | d1 f | b1 f
# +a +b ( c d ( e e2 f ) d1 f ) b1 f 
# c d (e e2 f) d1 f

proc mkhelpobj*(res: var object, skip = 0): seq[string] =
  var lvl = 0
  var i = 0  
  var rr: seq[seq[string]]
  for k, v in fieldPairs(res):
    if i >= skip:
      when v is enum:
        for e in low(typeof(v))..high(typeof(v)):
          {.cast(uncheckedAssign).}:
            v = e
          let r = mkhelpobj(res, i+1)
          let r2 = @[(repeat(".", lvl)) & "- " & $e] & r
          rr.add r2
          lvl += 1
      else:
        let h =
          when v.hasCustomPragma(aarg.help): v.getCustomPragmaVal(aarg.help)
          else: ""
        result.add repeat(",", lvl) & k & ": " & $typeof(v) & "  " & h
    inc i

proc mkhelp*[T: object](): string =
  var res = T()
  for x in mkhelpobj(res):
    echo x

when isMainModule:
# a b* b1 f
#   c* d* d1 f
#      e* e2 f
  type
    K1 = enum B, C
    K2 = enum D, E
    O = object
      a: int
      case k1: K1
      of B:
        case k2: K2
        of D:
          d1: int
        of E:
          e1: int
      of C:
        c1: int
      f: string


  proc main() =
    var o = O()

    var i = 0
    for k, v in fieldPairs(o):
      echo i, ": ", k, ": ", v
      when v is enum:
        for e in low(typeof(v))..high(typeof(v)):
          {.cast(uncheckedAssign).}:
            v = e
          echo "change to ", e
          for k2, v2 in fieldPairs(o):
            echo "  ", i, ": ", k2, ": ", v2
      inc i

  main()

