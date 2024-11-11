# remote add <name> <url>
# remote list
# remote remove <name>
# remote up add <name> <url>
# remote up rm <name>
# status

import argparse

var p = newParser:
  flag("-v", "--verbose")
  command("remote"):
    command("add"):
      arg("name")
      arg("url")
    command("list"):
      discard
    command("remove"):
      arg("name")
    command("up"):
      command("add"):
        arg("name")
        arg("url")
      command("rm"):
        arg("name")
  command("status"):
    discard

let x = p.parse(@["-v", "remote", "up", "add", "n1", "url1"])
echo x.argparse_status_opts.isSome
let a = x.remote.get.up.get.add.get
echo $a.parentOpts[]
