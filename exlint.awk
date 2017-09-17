#!/usr/bin/env gawk -f

match($0, /^warning:\s+(.*)$/, m) {
  capture = 1
  type = "W"
  desc = m[1]
}

match($0, /^\s*(.+)$/, m) {
  path = m[1]
}

/^$/ {
  if (capture == 1) {
    print path ": " type ": " desc
    capture = 0
  }
}

/^.+$/ {
  if (capture == 0) {
    print $0
  }
}
