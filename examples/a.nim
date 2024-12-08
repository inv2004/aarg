# remote add <name> <url>
# remote list
# remote remove <name>
# remote up add <name> <url>
# remote up rm <name>
# status

import aarg

type
  CmdKind = enum Cmd_Send, Cmd_Update, Cmd_Get

  Args = object
    verbose {.default:false.}: bool
    case cmd: CmdKind
    of Cmd_Send:
      send_chatId: int
    of Cmd_Update:
      upd_chatId: int
      upd_msgId: int
    of Cmd_Get:
      get_fileId: string

echo parseArgs(Args, "send 101")

