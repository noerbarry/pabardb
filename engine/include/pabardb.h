#pragma once
#ifdef __cplusplus
extern "C" {
#endif

typedef struct pabardb_handle pabardb_handle;

pabardb_handle* pabardb_open(const char* db_path);
void pabardb_close(pabardb_handle* h);

int pabardb_put_json(pabardb_handle* h,
                     const char* entity_type,
                     const char* entity_id,
                     const char* payload_json,
                     const char* actor);

int pabardb_get_json(pabardb_handle* h,
                     const char* entity_type,
                     const char* entity_id,
                     char** out_json);

int pabardb_recover(pabardb_handle* h);
void pabardb_free(void* p);

#ifdef __cplusplus
}
#endif

