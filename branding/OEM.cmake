set( APPLICATION_NAME       "Planio Storage" )
set( APPLICATION_SHORTNAME  "Planio Storage" )
set( APPLICATION_EXECUTABLE "PlanioStorage" )
set( APPLICATION_DOMAIN     "plan.io" )
set( APPLICATION_VENDOR     "Planio GmbH" )
set( APPLICATION_UPDATE_URL "https://storageclient-updates.plan.io/client/" CACHE STRING "URL for updater" )
set( APPLICATION_ICON_NAME  "PlanioStorage" )
set( APPLICATION_VIRTUALFILE_SUFFIX "planiostorage" CACHE STRING "Virtual file suffix (not including the .)")

set( LINUX_PACKAGE_SHORTNAME "planiostorage" )

set( THEME_CLASS            "PlanioTheme" )
set( APPLICATION_REV_DOMAIN "com.planio.storageclient" )
set( SOCKETAPI_TEAM_IDENTIFIER_PREFIX "7YBEE7ZG7K." )
set( WIN_SETUP_BITMAP_PATH  "${OEM_THEME_DIR}/win" )

set( MAC_INSTALLER_BACKGROUND_FILE "${OEM_THEME_DIR}/osx/installer-background.png" CACHE STRING "The MacOSX installer background image")

set( THEME_INCLUDE          "${OEM_THEME_DIR}/planiotheme.h" )
# set( APPLICATION_LICENSE    "${OEM_THEME_DIR}/license.txt )

option( WITH_CRASHREPORTER "Build crashreporter" OFF )

if(CPACK_GENERATOR MATCHES "NSIS")
    SET( CPACK_PACKAGE_ICON  "{OEM_THEME_DIR}/win/installer.ico" ) # Set installer icon
endif(CPACK_GENERATOR MATCHES "NSIS")
