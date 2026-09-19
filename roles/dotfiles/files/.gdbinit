source /usr/share/pwndbg/gdbinit.py
set context-sections regs disasm code stack backtrace

set debuginfod enabled off

set integration-provider binja
set show-compact-regs on
set show-tips off

set disassembly-flavor intel
set confirm off
set verbose off
set pagination off
set height 0
set width 0

set auto-load safe-path /

unset env LINES
unset env COLUMNS
