cmake_minimum_required(VERSION 3.16)
project(FreshetScientific VERSION 0.2.1 LANGUAGES NONE)

include(CTest)

if(NOT PENSTOCK_EXECUTABLE)
  find_program(_PENSTOCK_EXECUTABLE NAMES penstock)
  if(_PENSTOCK_EXECUTABLE)
    set(PENSTOCK_EXECUTABLE "${_PENSTOCK_EXECUTABLE}" CACHE FILEPATH "Path to the Penstock compiler" FORCE)
  endif()
endif()
if(NOT PENSTOCK_EXECUTABLE)
  message(FATAL_ERROR
    "Penstock was not found. Install Penstock and put it on PATH, or configure with -DPENSTOCK_EXECUTABLE=/path/to/penstock.")
endif()

function(freshet_add_sublibrary target directory archive)
  set(project_dir "${CMAKE_CURRENT_SOURCE_DIR}/${directory}")
  add_custom_target(${target}
    COMMAND "${PENSTOCK_EXECUTABLE}" build "${project_dir}"
    WORKING_DIRECTORY "${project_dir}"
    BYPRODUCTS "${project_dir}/${archive}"
    COMMENT "Building ${target} with Penstock"
    VERBATIM)
endfunction()

freshet_add_sublibrary(freshet_numerics "Freshet-Numerics" "libfreshet_numerics.a")
freshet_add_sublibrary(freshet_fluid "Freshet-Fluid" "libfreshet_fluid.a")
freshet_add_sublibrary(freshet_data "Freshet-Data" "libfreshet_data.a")
freshet_add_sublibrary(freshet_mechanics "Freshet-Mechanics" "libfreshet_mechanics.a")
add_dependencies(freshet_mechanics freshet_numerics)

add_custom_target(freshet_scientific ALL
  DEPENDS freshet_numerics freshet_fluid freshet_data freshet_mechanics)

if(BUILD_TESTING)
  add_test(NAME numerics
    COMMAND "${PENSTOCK_EXECUTABLE}" test
            "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Numerics/tests/test_numerics.fsht"
            "-I${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Numerics/src")
  add_test(NAME fluid
    COMMAND "${PENSTOCK_EXECUTABLE}" test
            "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Fluid/tests/test_fluid.fsht"
            "-I${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Fluid/src")
  add_test(NAME data
    COMMAND "${PENSTOCK_EXECUTABLE}" test
            "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Data/tests/test_data.fsht"
            "-I${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Data/src")
  add_test(NAME mechanics
    COMMAND "${PENSTOCK_EXECUTABLE}" test
            "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Mechanics/tests/test_mechanics.fsht"
            "-I${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Mechanics/src"
            "-I${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Numerics/src")
  set_tests_properties(numerics PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Numerics")
  set_tests_properties(fluid PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Fluid")
  set_tests_properties(data PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Data")
  set_tests_properties(mechanics PROPERTIES
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Freshet-Mechanics")
endif()
