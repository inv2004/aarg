import unittest

import aarg

test "bool":
  type B = object
    verbose: bool
  check parseArgs(B, "--verbose:t") == B(verbose: true)
  check parseArgs(B, "--verbose:true") == B(verbose: true)
  check parseArgs(B, "-v:t") == B(verbose: true)
  check parseArgs(B, "-v:1") == B(verbose: true)
  check parseArgs(B, "-v=1") == B(verbose: true)
  check parseArgs(B, "-v:true") == B(verbose: true)
  check parseArgs(B, "-v:0") == B(verbose: false)
  check parseArgs(B, "-v:f") == B(verbose: false)

test "int":
  type B = object
    i: int
  check parseArgs(B, "1") == B(i: 1)
  expect ValueError:
    discard parseArgs(B, "1.1")

test "float":
  type B = object
    f: float
  check parseArgs(B, "1.1") == B(f: 1.1)
  expect ValueError:
    discard parseArgs(B, "1.1a")

test "string":
  type B = object
    s1: string
    s2: string
  check parseArgs(B, "111 222") == B(s1: "111", s2: "222")

test "enum":
  type
    E = enum C, D
    B = object
      e: E
  check parseArgs(B, "D") == B(e: D)
  expect ValueError:
    discard parseArgs(B, "E")

test "multi":
  type
    E = enum C, D
    B = object
      i: int
      s: string
      e: E
      f: float
  check parseArgs(B, "-f=1.1 -i=1 222 D") == B(i:1, s: "222", e: D, f:1.1)
  expect ValueError:
    discard parseArgs(B, "-f=1.1 222 D -i=1")

test "default":
  type
    E = enum C, D
    B = object
      i {.deff: 1.}: int
      s {.deff: "222".}: string
      e {.deff: "d".}: E
      f {.deff: 1.1.}: float
  check parseArgs(B, "") == B(i:1, s: "222", e: D, f:1.1)

type
  Cmd1Kind = enum CmdA, CmdB
  Cmd2Kind = enum CmdAA, CmdBB, CmdCC
  AAEnum = enum P, U

  B = object
    v: bool
    case kind {.deff: "CmdB".}: Cmd1Kind
    of CmdA:
      discard
    of CmdB:
      case b_kind {.deff: "CmdCC".}: Cmd2Kind
      of CmdAA:
        e: AAEnum
        names: seq[string]
      of CmdBB:
        up_name: string
        up_url: string
        up_v: bool
      of CmdCC:
        name {.deff: "d1".}: string
        num {.deff: 11.}: int
        num2 {.deff: 0.}: int

proc `==`(a, b: B): bool =
  $a == $b

test "cmd":
  check parseArgs(B, "-v cmdb cmdbb n1 u1 -v") == B(v: true, kind: CmdB, b_kind: CmdBB, up_name: "n1", up_url: "u1", up_v: true)
  check parseArgs(B, "-v cmdb cmdaa -e:u n1 n2") == B(v: true, kind: CmdB, b_kind: CmdAA, e: U, names: @["n1", "n2"])
  check parseArgs(B, "-v cmdb cmdcc") == B(v: true, kind: CmdB, b_kind: CmdCC, name: "d1", num: 11, num2: 0)
  check parseArgs(B, "-v --num:22") == B(v: true, kind: CmdB, b_kind: CmdCC, name: "d1", num: 22, num2: 0)

