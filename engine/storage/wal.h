#pragma once
#include <string>

class WAL {
public:
  explicit WAL(const std::string& path);
  void append(const std::string& line);
  std::string path() const { return path_; }
private:
  std::string path_;
};

