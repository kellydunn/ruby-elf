#include <list>

namespace mynamespace {
  std::list<int> list_of_ints;

  void function() {}
  void function(int a, bool b) {}
  void function(int *a, bool b, void *c) {}
  void function(unsigned int a, char &b) {}
  void function(long a, ...) {}
  void function(const signed char *a) {}
  void function(signed char *const a) {}
  void function(const volatile float *a) {}
  void function(const double &a) {}
}