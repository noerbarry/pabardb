#include "../include/pabardb.h"
#include <iostream>
#include <string>

static void usage(){
  std::cout <<
"Usage:\n"
"  pabardb <db.pbr> \"PUT <type> <id> '<json>'\"\n"
"  pabardb <db.pbr> \"GET <type> <id>\"\n"
"  pabardb <db.pbr> \"RECOVER\"\n";
}

int main(int argc, char** argv){
  if(argc < 3){ usage(); return 1; }
  const char* db = argv[1];
  std::string cmd = argv[2];

  pabardb_handle* h = pabardb_open(db);
  if(!h){ std::cerr<<"open failed\n"; return 2; }

  auto fail=[&](const char* m){ std::cerr<<m<<"\n"; pabardb_close(h); return 3; };

  if(cmd.rfind("PUT ",0)==0){
    auto s = cmd.substr(4);
    auto p1 = s.find(' '); if(p1==std::string::npos) return fail("Bad PUT");
    auto p2 = s.find(' ', p1+1); if(p2==std::string::npos) return fail("Bad PUT");
    std::string type = s.substr(0,p1);
    std::string id   = s.substr(p1+1, p2-(p1+1));
    std::string json = s.substr(p2+1);
    if(!json.empty() && (json.front()=='"'||json.front()=='\'')) json.erase(0,1);
    if(!json.empty() && (json.back()=='"' ||json.back()=='\'')) json.pop_back();

    if(pabardb_put_json(h, type.c_str(), id.c_str(), json.c_str(), "cli")!=0)
      return fail("PUT failed");
    std::cout<<"OK\n";
  }
  else if(cmd.rfind("GET ",0)==0){
    auto s = cmd.substr(4);
    auto p1 = s.find(' '); if(p1==std::string::npos) return fail("Bad GET");
    std::string type = s.substr(0,p1);
    std::string id   = s.substr(p1+1);

    char* out=nullptr;
    if(pabardb_get_json(h, type.c_str(), id.c_str(), &out)!=0)
      return fail("GET failed");
    std::cout<<out<<"\n";
    pabardb_free(out);
  }
  else if(cmd=="RECOVER"){
    if(pabardb_recover(h)!=0) return fail("RECOVER failed");
    std::cout<<"OK\n";
  }
  else { usage(); pabardb_close(h); return 1; }

  pabardb_close(h);
  return 0;
}

