#include "engine.h"
#include <filesystem>
#include <fstream>
#include <sstream>
#include <iostream>
#include <ctime>

using namespace std;

void Engine::ensureLayout(){
  namespace fs = std::filesystem;
  fs::create_directories(root_);
  fs::create_directories(root_ + "/wal");
  fs::create_directories(root_ + "/segments");
  // manifest
  ofstream m(root_ + "/manifest.json");
  m << "{ \"engine\":\"PABAR DB\",\"format\":\"pbr\",\"version\":\"1.0.0\" }\n";
  // wal file
  ofstream w(root_ + "/wal/wal-active.log", ios::app);
}

void Engine::openOrCreate(const std::string& db_path){
  root_ = db_path;
  ensureLayout();
  wal_ = new WAL(root_ + "/wal/wal-active.log");
  recover();
}

void Engine::write(const Event& e){
  // format: type|id|payload|actor|ts
  std::stringstream ss;
  ss << e.entity_type << "|" << e.entity_id << "|" << e.payload
     << "|" << e.actor << "|" << e.ts;
  wal_->append(ss.str());
  state_[e.entity_type + ":" + e.entity_id] = e.payload;
}

std::string Engine::read(const std::string& type, const std::string& id){
  auto k = type + ":" + id;
  auto it = state_.find(k);
  if(it == state_.end()) return "{}";
  return it->second;
}

void Engine::recover(){
  state_.clear();
  std::ifstream in(root_ + "/wal/wal-active.log");
  std::string line;
  while(std::getline(in, line)){
    std::stringstream ss(line);
    std::string t,id,payload,actor,ts;
    std::getline(ss, t, '|');
    std::getline(ss, id, '|');
    std::getline(ss, payload, '|');
    std::getline(ss, actor, '|');
    std::getline(ss, ts, '|');
    state_[t + ":" + id] = payload;
  }
}

