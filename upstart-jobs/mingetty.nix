{mingetty, ttyNumber, loginProgram}:

{
  #name = "tty" + toString ttyNumber;
  name = "hvc" + toString ttyNumber;
  job = "
    start on udev
    stop on shutdown
    respawn ${mingetty}/sbin/mingetty --loginprog=${loginProgram} --noclear hvc${toString ttyNumber}
  ";
}
