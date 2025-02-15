import unittest

import aarg

test "bool":
  aargs:
    type
      A = ref object of RootObj
        verbose: bool
      C = ref object of B
        id: int
      B = ref object of A
        id: int

  echo B()[]
  echo parse[A]("-verbose")
  check 2 == 2
