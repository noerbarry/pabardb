#include "../include/pabardb.h"
#include "../core/engine.h"
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <new>

struct pabardb_handle { Engine db; };

static char* dup(const std::string& s){
  char* p = (char*)std::malloc(s.size()+1);
  if(!p) return nullptr;
  std::memcpy(p, s.c_str(), s.size()+1);
  return p;
}

extern "C" {

pabardb_handle* pabardb_open(const char* db_path){
  if(!db_path) return nullptr;
  auto* h = new (std::nothrow) pabardb_handle();
  if(!h) return nullptr;
  try { h->db.openOrCreate(db_path); return h; }
  catch(...) { delete h; return nullptr; }
}

void pabardb_close(pabardb_handle* h){ delete h; }

int pabardb_put_json(pabardb_handle* h,
                     const char* entity_type,
                     const char* entity_id,
                     const char* payload_json,
                     const char* actor){
  if(!h||!entity_type||!entity_id||!payload_json) return -1;
  Event e;
  e.entity_type = entity_type;
  e.entity_id   = entity_id;
  e.payload     = payload_json;
  e.actor       = actor ? actor : "system";
  e.ts          = std::time(nullptr);
  try { h->db.write(e); return 0; } catch(...) { return -2; }
}

int pabardb_get_json(pabardb_handle* h,
                     const char* entity_type,
                     const char* entity_id,
                     char** out_json){
  if(!h||!entity_type||!entity_id||!out_json) return -1;
  try {
    auto s = h->db.read(entity_type, entity_id);
    *out_json = dup(s);
    return *out_json ? 0 : -3;
  } catch(...) { return -2; }
}

int pabardb_recover(pabardb_handle* h){
  if(!h) return -1;
  try { h->db.recover(); return 0; } catch(...) { return -2; }
}

void pabardb_free(void* p){ std::free(p); }

} // extern "C"

