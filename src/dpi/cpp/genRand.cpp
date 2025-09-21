#include <svdpi.h>

#include <time.h>
#include <stdlib.h>

extern "C" void genRand_seed() {
  // Seed the random number generator...
  srand(time(NULL));
}

extern "C" int genRand() {
  return rand();
}
