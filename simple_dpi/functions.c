#include "svdpi.h"

DPI_DLLESPEC
int count_s()
{
    static uint8_t t = 0;
    t++;
    return t;
}

DPI_DLLESPEC
int count()
{
    uint8_t t = 0;
    t++;
    return t;
}
