#include <sysbus.hh>

#include <iostream>

int main() {
    fetch();
#ifdef DEBUG_MODE
    std::cout << "Hello" << std::endl;
#endif
    return 0;
}