{mingetty, ttyNumber, loginProgram}:

{
  #name = "tty" + toString ttyNumber;
  name = "hvc" + toString ttyNumber;
  job = "
    start on startup
    stop on shutdown
    respawn ${mingetty}/sbin/mingetty --loginprog=${loginProgram} --noclear tty${toString ttyNumber}
  ";
}
