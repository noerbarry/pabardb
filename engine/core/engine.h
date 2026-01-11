#pragma once
#include <string>
#include <unordered_map>
#include "../storage/wal.h"

struct Event {
  std::string entity_type;
  std::string entity_id;
  std::string payload;
  std::string actor;
  long ts{0};
};

class Engine {
public:
  void openOrCreate(const std::string& db_path);
  void write(const Event& e);
  std::string read(const std::string& type, const std::string& id);
  void recover();

private:
  std::string root_;
  WAL* wal_{nullptr};
  std::unordered_map<std::string,std::string> state_;
  void ensureLayout();
};

