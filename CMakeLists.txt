


# 1. Support straight build of app:
#    1. Absolute path.
#    2. Relative to Zephyr base
#    3. Relative to `west workspace ?
#    4. Relative to a Zephyr module ?
# 2. Scan for sample.yml and populate Kconfig
# 3. Support Kconfig / menuconfig for bootloader and other multi image projects.

cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED APP_DIR)
  message(FATAL_ERROR "No main application specified"
                      "Please specify the main app tp build with:\n"
                      "`-DAPP_DIR=<path-to-application>"
  )
endif()

# This ensures we can find the right Zephyr for loading of additional tools
# without loading the boilerplate code.
set(NO_BOILERPLATE TRUE)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

include(zephyr.cmake)
include(cmake/extensions.cmake)
include(${ZEPHYR_BASE}/cmake/extensions.cmake)

project(multi_image LANGUAGES)

set(KCONFIG_ROOT           ${CMAKE_CURRENT_LIST_DIR}/Kconfig)
set(KCONFIG_BINARY_DIR     ${CMAKE_CURRENT_BINARY_DIR})
set(CONF_FILE              ${CMAKE_CURRENT_LIST_DIR}/prj.conf)
set(APPLICATION_SOURCE_DIR ${APP_DIR})
set(AUTOCONF_H             ${CMAKE_CURRENT_BINARY_DIR}/autoconf.h)
set(BOARD_DEFCONFIG        "${CMAKE_CURRENT_LIST_DIR}/dummy.conf")
file(TOUCH ${KCONFIG_BINARY_DIR}/Kconfig.modules) 
include(${ZEPHYR_BASE}/cmake/kconfig.cmake)

get_filename_component(APP_DIR  ${APP_DIR} ABSOLUTE)
get_filename_component(app_name ${APP_DIR} NAME)

ExternalZephyrProject_Add(
  APPLICATION ${app_name}
  SOURCE_DIR ${APP_DIR}
  MAIN_APP
)

if(CONFIG_BOOTLOADER_MCUBOOT)
  ExternalZephyrProject_Add(
    APPLICATION mcuboot
    # TODO: Temphack for prototype, need support for Zephyr modules to be able
    #       to refer to as: ZEPHYR_MCUBOOT_MODULE_DIR/boot/zephyr
    SOURCE_DIR ${ZEPHYR_BASE}/../bootloader/mcuboot/boot/zephyr/
  )
endif()

