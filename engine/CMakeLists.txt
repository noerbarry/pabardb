cmake_minimum_required(VERSION 3.16)
project(pabardb C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(PABAR_CORE
  core/engine.cpp
  storage/wal.cpp
)

add_library(pabardb SHARED
  ${PABAR_CORE}
  c_api/pabardb_c.cpp
)

target_include_directories(pabardb PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}
)

add_executable(pabardb_cli
  cli/main.cpp
)
target_link_libraries(pabardb_cli PRIVATE pabardb)

install(TARGETS pabardb pabardb_cli
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)
install(FILES include/pabardb.h DESTINATION include)

