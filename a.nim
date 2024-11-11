# remote add <name> <url>
# remote list
# remote remove <name>
# remote up add <name> <url>
# remote up rm <name>
# status

type
  Cmd1Kind = enum Remote, Status
  Cmd2Kind = enum Add, List, Remove, Up
  Cmd3Kind = enum Add, Rm

  A = object
    verbose: bool
    case cmd1kind: Cmd1Kind
    of Status:
      discard
    of Remote:
      case cmd2kind: Cmd2Kind
      of Add:
        name: string
        url: string
      of List:
        discard
      of Remove:
        name2: string
      of Up:
        case cmd3kind: Cmd3Kind
        of Add:
          name3: string
          url2: string
        of Rm:
          name4: string

  B = object of RootObj
    verbose: bool

  StatusB = object of B

  RemoteB = object of B

  AddRemoteB = object of RemoteB
    name, url: string

  ListRemoteB = object of RemoteB

  RemoveRemoteB = object of RemoteB

  UpRemoteB = object of RemoteB

  AddUpRemoteB = object of UpRemoteB
    name: string
    url: string

  RmUpRemoteB = object of UpRemoteB
    name: string

let a = A(verbose: true, cmd1kind: Remote, cmd2kind: Up, cmd3kind: Add, name3: "n", url2: "1.url")
proc f(a: A) =
  if a.cmd1kind == Remote and a.cmd2kind == Up and a.cmd3kind == Add:
    echo "A: ", a.verbose, " ", a.name3, a.url2
f(a)

let b =
  if true:
    AddUpRemoteB(verbose: true, name: "n", url: "1.url")
  else:
    RmUpRemoteB(verbose: true, name: "n")
method f(b: AddUpRemoteB) =
  echo "B: ", b.verbose, " ", b.name, b.url
method f(b: RmUpRemoteB) =
  echo "B: ", b.verbose, " ", b.name

f(b)

