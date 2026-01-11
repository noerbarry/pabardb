#include "wal.h"
#include <fstream>

WAL::WAL(const std::string& path): path_(path) {}

void WAL::append(const std::string& line){
  std::ofstream o(path_, std::ios::app);
  o << line << "\n";
  o.flush(); // crash-safe point
}

