import std/parseopt
import std/macros
import std/tables

proc transform[T](x: ref object): T =
  let res = T()
  for k, v in fieldPairs(res[]):
    for kk, vv in fieldPairs(x[]):
      when k == kk:
        v = vv
        break
  res

proc f(t: OrderedTable[string, seq[string]], n: string, lvl = 0): seq[(string, int)] =
  if n in t:
    for x in t[n]:
      result.add f(t, x, lvl+1)
      result.add (x, lvl+1)

proc genCase(t: string, tt: seq[string]): NimNode =
  result = nnkCaseStmt.newTree(
    newIdentNode("a")
  )

  for t in tt:
    result.add nnkOfBranch.newTree(
      nnkPrefix.newTree(
        newIdentNode("$"),
        nnkCall.newTree(
          newIdentNode("typeof"),
          newIdentNode(t)
        )
      ),
      nnkStmtList.newTree(
        nnkAsgn.newTree(
          newIdentNode("result"),
          nnkCall.newTree(
            nnkBracketExpr.newTree(
              newIdentNode("transform"),
              newIdentNode(t)
            ),
            newIdentNode("result")
          )
        )
      )
    )

  result.add nnkElse.newTree(
    quote do:
      raise newException(ValueError, "err " & `t` & ": " & a)
  )

proc genIf(t: string, tt: seq[string], isRoot: bool): NimNode =
  if isRoot:
    result = nnkElse.newTree()
  else:
    result = nnkElifBranch.newTree(
      nnkInfix.newTree(
        newIdentNode("of"),
        newIdentNode("result"),
        newIdentNode(t)
      )
    )
  result.add genCase(t, tt)

proc genTemplate(t: OrderedTable[string, seq[string]]): NimNode =
  let ifStmt = nnkIfStmt.newTree()

  var i = 1
  for k, v in t:
    ifStmt.add genIf(k, v, i == len(t))
    inc i

  nnkStmtList.newTree(
    nnkTemplateDef.newTree(
      newIdentNode("parseCmd"),
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        newIdentNode("untyped"),
        nnkIdentDefs.newTree(
          newIdentNode("a"),
          newIdentNode("string"),
          newEmptyNode()
        )
      ),
      newEmptyNode(),
      newEmptyNode(),
      nnkStmtList.newTree(
        ifStmt
      )
    )
  )

macro aargs*(body: untyped): typed =
  var rels = initOrderedTable[string, seq[string]]()

  for x in body:
    if x.kind == nnkMethodDef:
      continue
    expectKind x, nnkTypeSection
    for y in x:
      expectKind y, nnkTypeDef
      expectKind y[0], nnkIdent
      expectKind y[2], nnkRefTy
      expectKind y[2][0], nnkObjectTy
      expectKind y[2][0][1], nnkOfInherit
      expectKind y[2][0][1][0], nnkIdent
      let o = strVal(y[0])
      let po = strVal(y[2][0][1][0])
      rels.mgetOrPut(po).add(o)

  var lvls = f(rels, "RootObj").toTable()
  echo lvls

  let root = rels["RootObj"][0]
  rels.del "RootObj"
  rels.sort(func(a, b:(string, seq[string])): int = cmp(lvls[b[0]], lvls[a[0]]))

  let t = genTemplate(rels)

  let rootId = newIdentNode(root)

  let p = quote do:
    proc parse*(aa: seq[string]): `rootId` =
      result = `rootId`()
      for a in aa:
        var found = false
        for k, v in fieldPairs(result[]):
          if "-" & k == a:
            when v is bool:
              v = true
              found = true
              break
        if found:
          continue
        parseCmd(a)

  newStmtList(
    body,
    t,
    p
  )

when isMainModule:
  aargs:
    type
      A = ref object of RootObj
        verbose: bool
      C = ref object of B
        di: int
      B = ref object of A
        id: int

    method run(a: A) {.base.} =
      echo "its A"
    method run(b: B) =
      echo "its B: ", b.id
    method run(c: C) =
      echo "its C"

  parse(@["-verbose", "B"]).run()
