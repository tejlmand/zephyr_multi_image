
# Usage:
#   ExternalZephyrProject_Add(...)
#
# This function includes a Zephyr based build system into the multiimage
# build system
#
# APPLICATION: <name>: Name of the application, name will also be used for build
#                      folder of the application
# SOURCE_DIR <dir>:    Source directory of the application
# BOARD <board>:       Use <board> for application build instead user defined BOARD.
# MAIN_APP:            Flag indicating this application is the main application
#                      and where user defined settings should be passed on as-is
#                      except for multi image build flags.
#                      For example, -DCONF_FILES=<files> will be passed on to the
#                      MAIN_APP unmodified.
#
function(ExternalZephyrProject_Add)
  cmake_parse_arguments(ZBUILD "MAIN_APP" "APPLICATION;BOARD;SOURCE_DIR" "" ${ARGN})

  # TODO: Argument verification. Not required for the prototype but important later.
  #       If this comment is still present when PR is not in draft state, please make a review comment here.

  set(multi_image_build_vars
      "APP_DIR"
  )
  
  set(app_cache_file ${CMAKE_BINARY_DIR}/CMake${ZBUILD_APPLICATION}PreloadCache.txt)
  
  if(EXISTS ${app_cache_file})
    file(STRINGS ${app_cache_file} app_cache_strings)
    set(app_cache_strings_current ${app_cache_strings})
  endif()
  
  get_cmake_property(variables_cached CACHE_VARIABLES)
  foreach(var_name ${variables_cached})
    if(var_name IN_LIST multi_image_build_vars)
      continue()
    endif()

    # Any var of the form `<app>_<var>` should be propagated.
    # For example mcuboot_<VAR>=<val> ==> -D<VAR>=<val> for mcuboot build.
    if(${var_name} MATCHES "^${ZBUILD_APPLICATION}_")
      list(APPEND application_vars ${var_name})
    endif()

    if(ZBUILD_MAIN_APP)
      get_property(var_help CACHE ${var_name} PROPERTY HELPSTRING)
      if("${var_help}" STREQUAL "No help, variable specified on the command line.")
        list(APPEND main_vars ${var_name})
      endif()
    endif()
  endforeach()

  foreach(main_var_name ${main_vars})
    get_property(main_var_type  CACHE ${main_var_name} PROPERTY TYPE)
    set(new_cache_entry "${main_var_name}:${main_var_type}=${${main_var_name}}")
    if(NOT new_cache_entry IN_LIST app_cache_strings)
      # This entry does not exists, let's see if it has been updated.
      foreach(entry ${app_cache_strings})
        if(${entry} MATCHES "^${main_var_name}")
          list(REMOVE_ITEM app_cache_strings ${entry})
          break()
        endif()
      endforeach()
      list(APPEND app_cache_strings "${main_var_name}:${main_var_type}=${${main_var_name}}")
      list(APPEND app_cache_entries "-D${main_var_name}:${main_var_type}=${${main_var_name}}")
    endif()
  endforeach()

  foreach(app_var_name ${application_vars})
    string(REGEX REPLACE "^{ZBUILD_APPLICATION}_" "" var_name ${app_var_name})
    get_property(var_type  CACHE ${app_var_name} PROPERTY TYPE)
    set(new_cache_entry "${var_name}:${var_type}=${${app_var_name}}")
    if(NOT new_cache_entry IN_LIST app_cache_strings)
      # This entry does not exists, let's see if it has been updated.
      foreach(entry ${app_cache_strings})
        if(${entry} MATCHES "^${var_name}")
          list(REMOVE_ITEM app_cache_strings ${entry})
          break()
        endif()
      endforeach()
      list(APPEND app_cache_strings "${var_name}:${var_type}=${${app_var_name}}")
      list(APPEND app_cache_entries "-D${var_name}:${var_type}=${${app_var_name}}")
    endif()
  endforeach()

  if(NOT "${app_cache_strings_current}" STREQUAL "${app_cache_strings}")
    string(REPLACE ";" "\n" app_cache_strings "${app_cache_strings}")
    file(WRITE ${app_cache_file} ${app_cache_strings})
  endif()

  if(DEFINED ZBUILD_BOARD)
    list(APPEND app_cache_entries "-DBOARD=${ZBUILD_BOARD}")
  elseif(NOT ZBUILD_MAIN_APP)
    list(APPEND app_cache_entries "-DBOARD=${BOARD}")
  endif()

  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -G${CMAKE_GENERATOR}
      ${app_cache_entries}
      -B${CMAKE_BINARY_DIR}/${ZBUILD_APPLICATION}
      -S${ZBUILD_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

  include(ExternalProject)
  ExternalProject_Add(
    ${ZBUILD_APPLICATION}
    SOURCE_DIR ${ZBUILD_SOURCE_DIR}
    BINARY_DIR ${CMAKE_BINARY_DIR}/${ZBUILD_APPLICATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${CMAKE_COMMAND} --build .
    INSTALL_COMMAND ""
    BUILD_ALWAYS True
    USES_TERMINAL_BUILD True
  )
endfunction()
