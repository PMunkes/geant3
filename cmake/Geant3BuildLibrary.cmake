#------------------------------------------------
# The Virtual Monte Carlo packages
# Copyright (C) 2014 Ivana Hrivnacova
# All rights reserved.
#
# For the licensing terms see geant4_vmc/LICENSE.
# Contact: root-vmc@cern.ch
#-------------------------------------------------

# CMake Configuration file for geant4_vmc
# I. Hrivnacova, 13/06/2014

#---CMake required version -----------------------------------------------------
cmake_minimum_required(VERSION 2.6.4 FATAL_ERROR)

#-- ROOT (required) ------------------------------------------------------------
if(NOT ROOT_FOUND)
  find_package(ROOT REQUIRED)
endif(NOT ROOT_FOUND)  
include_directories(${ROOT_INCLUDE_DIRS})

#-------------------------------------------------------------------------------
# Setup project include directories; compile definitions; link libraries
#
include_directories(
  ${PROJECT_SOURCE_DIR}
  ${PROJECT_SOURCE_DIR}/minicern
  ${PROJECT_SOURCE_DIR}/TGeant3 
  ${CMAKE_CURRENT_BINARY_DIR})

#-------------------------------------------------------------------------------
# Generate Root dictionaries
#
ROOT_GENERATE_DICTIONARY(
  ${CMAKE_SHARED_LIBRARY_PREFIX}geant321
  with_rootmap
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/G3Material.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/G3Medium.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/G3Node.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/G3Volume.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TCallf77.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TG3Application.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TGeant3f77.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TGeant3gu.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TGeant3.h
  ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/TGeant3TGeo.h
  LINKDEF ${CMAKE_CURRENT_SOURCE_DIR}/TGeant3/geant3LinkDef.h)

#-------------------------------------------------------------------------------
# Adjust compiler flags and configuration
#

# receive warnings and force fix of uninitialized variables
add_definitions(-Wall -finit-local-zero)

# make sure a default build type is used
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo
       MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)


#-------------------------------------------------------------------------------
# Locate sources for this project
#
set(directories
    added gtrak gcons geocad ggeom gheisha ghits ghrout ghutils giface giopa
    gkine gparal gscan gbase matx55 miface miguti neutron peanut
    fiface cgpack fluka block comad erdecks erpremc gdraw
    gstrag gbase)

# directories needing special compiler treatment (less optimization)
set(specialdir
    minicern gphys)


# Fortran sources
set(fortran_sources gcinit.F)
foreach(_directory ${directories})
  file(GLOB add_f_sources
       ${PROJECT_SOURCE_DIR}/${_directory}/*.F)
  list(APPEND fortran_sources ${add_f_sources})
endforeach()
list(APPEND fortran_sources ${PROJECT_SOURCE_DIR}/minicern/lnxgs/rdmin.F)

foreach(_directory ${specialdir})
  file(GLOB special_f_sources
       ${PROJECT_SOURCE_DIR}/${_directory}/*.F)
    foreach(_file ${special_f_sources})
      if(NOT CMAKE_BUILD_TYPE MATCHES Debug)
       set_source_files_properties(${_file} PROPERTIES COMPILE_FLAGS -O1)
      endif()
      list(APPEND fortran_sources ${_file})
    endforeach()
endforeach()

# Exclude some files from the list
list(REMOVE_ITEM fortran_sources ${PROJECT_SOURCE_DIR}/gtrak/grndm.F)
list(REMOVE_ITEM fortran_sources ${PROJECT_SOURCE_DIR}/gtrak/grndmq.F)
list(REMOVE_ITEM fortran_sources ${PROJECT_SOURCE_DIR}/erdecks/eustep.F)
#message(STATUS "fortran_sources ${fortran_sources}")
       
# C sources
set(c_sources)
foreach(_directory ${directories} ${specialdir})
  file(GLOB add_c_sources 
       ${PROJECT_SOURCE_DIR}/${_directory}/*.c)
  list(APPEND c_sources ${add_c_sources})
endforeach()
list(APPEND c_sources ${PROJECT_SOURCE_DIR}/minicern/lnxgs/ishftr.c)
# Linux specific, the file is kept on macosx, macosx64)
list(REMOVE_ITEM c_sources ${PROJECT_SOURCE_DIR}/minicern/lnblnk.c)
#message(STATUS "c_sources ${c_sources}")
       
# C++ sources
file(GLOB cxx_sources 
     ${PROJECT_SOURCE_DIR}/comad/gcadd.cxx
     ${PROJECT_SOURCE_DIR}/TGeant3/*.cxx)
#message(STATUS "cxx_sources ${cxx_sources}")
       
#-------------------------------------------------------------------------------
# Locate headers for this project
#
file(GLOB headers ${PROJECT_SOURCE_DIR}/TGeant3/*.h)

#---Add definitions-------------------------------------------------------------
add_definitions(-DCERNLIB_LXIA64 -DCERNLIB_BLDLIB -DCERNLIB_CZ)
# Architecture dependent not ported flags:
# -DCERNLIB_LINUX (linux, linuxx8664icc, linuxicc, macosx, macosxxlc, macosicc)
# -DCERNLIB_PPC (macosx64, macosxxlc, macosicc)
# -DCERNLIB_UNIX (alphagcc)
# -DCERNLIB_DECS (alphagcc, alphacxx6)
# -DCERNLIB_SUN (solarisCC5)
# -DCERNLIB_HPUX (hpuxacc)
if (${CMAKE_Fortran_COMPILER} MATCHES gfortran+)
  add_definitions(-DCERNLIB_GFORTRAN)
endif()
if (${CMAKE_Fortran_COMPILER} MATCHES gfortran+)
  add_definitions(-DCERNLIB_GFORTRAN)
endif()
if (${CMAKE_Fortran_COMPILER} MATCHES g95+)
  add_definitions(-DCERNLIB_G95)
endif()
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  # using Clang
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -undefined dynamic_lookup")
endif()

#---Add library-----------------------------------------------------------------
add_library(geant321 ${fortran_sources} ${c_sources} ${cxx_sources}
            ${CMAKE_SHARED_LIBRARY_PREFIX}geant321_dict.cxx ${headers})
target_link_libraries(geant321 ${ROOT_LIBRARIES} -lVMC -lEG)

#----Installation---------------------------------------------------------------
install(FILES ${headers} DESTINATION include/TGeant3)
install(TARGETS geant321 EXPORT Geant3Targets DESTINATION ${CMAKE_INSTALL_LIBDIR})

# Install dictionary map (only if ROOT 6.x
if (${ROOT_FOUND_VERSION} GREATER 59999)
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}geant321_dict_rdict.pcm
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}geant321.rootmap
    DESTINATION ${CMAKE_INSTALL_LIBDIR})
endif()
