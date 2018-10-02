#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/serial.h>
  
#define TIOCGRS485      0x542E
#define TIOCSRS485      0x542F

int main(int argc, char ** argv) {

  if (argc < 2) {
    printf("usage: %s [tty dev]\n", argv[0]);
    exit(0);
  }

  char * port = argv[1];

  int fd = open(port, O_RDWR);
  if (fd < 0) {
    fprintf(stderr, "Error opening port \"%s\" (%d): %s\n", port, errno, strerror(errno));
    exit(-1);
  }

  struct serial_rs485 rs485conf;

  if (ioctl(fd, TIOCGRS485, & rs485conf) < 0) {
    fprintf(stderr, "Error reading ioctl port (%d): %s\n", errno, strerror(errno));
  }

  // enable rs485
  rs485conf.flags |= SER_RS485_ENABLED;

  if (ioctl(fd, TIOCSRS485, & rs485conf) < 0) {
    fprintf(stderr, "error sending ioctl port (%d): %s\n", errno, strerror(errno));
  }

  if (close(fd) < 0) {
    fprintf(stderr, "error closing port (%d): %s\n", errno, strerror(errno));
  }

  exit(0);
}
