cmake_minimum_required(VERSION 3.15)
project(ANUGA_Setup)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
message(STATUS "Checking for required system packages...")

# GDAL (OPTIONAL)
pkg_check_modules(GDAL gdal)
if(GDAL_FOUND)
  message(STATUS "Found GDAL: ${GDAL_VERSION}")
else()
  message(STATUS "GDAL not found (ok). Some GIS features will be unavailable.")
endif()

# NetCDF (required)
pkg_check_modules(NETCDF REQUIRED netcdf)
if(NETCDF_FOUND)
  message(STATUS "Found NetCDF: ${NETCDF_VERSION}")
else()
  message(FATAL_ERROR "NetCDF not found. Install netcdf development package for your OS.")
endif()

# MPI (required)
find_package(MPI REQUIRED)
if(MPI_FOUND)
  message(STATUS "Found MPI")
  message(STATUS "MPI C compiler: ${MPI_C_COMPILER}")
  message(STATUS "MPI CXX compiler: ${MPI_CXX_COMPILER}")
else()
  message(FATAL_ERROR "MPI not found. Install OpenMPI/MPICH development package for your OS.")
endif()

# Clone ANUGA repository if not present
set(ANUGA_DIR "${CMAKE_CURRENT_SOURCE_DIR}/anuga_core")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/clone_anuga.sh
"#!/bin/bash
set -e
if [ ! -d \"${ANUGA_DIR}\" ]; then
  echo \"Cloning ANUGA repository...\"
  git clone https://github.com/GeoscienceAustralia/anuga_core.git \"${ANUGA_DIR}\"
  cd \"${ANUGA_DIR}\"
  # NOTE: update this tag/branch as you prefer
  git checkout 3.2.0 || true
  echo \"ANUGA repository cloned successfully.\"
else
  echo \"ANUGA source already present at ${ANUGA_DIR}\"
fi
")

add_custom_target(clone_anuga
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/clone_anuga.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/clone_anuga.sh
  COMMENT "Cloning ANUGA repository"
)

# Build ANUGA (depends on cloning first)
# NOTE: We use --no-deps because setup.sh already installed all dependencies
# This avoids duplicate installations and version conflicts
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh
"#!/bin/bash
set -e

# Add user local bin to PATH for meson, cython, etc.
export PATH=\"\$HOME/.local/bin:\$PATH\"

# Determine pip flags
PIP_FLAGS=\"--break-system-packages\"
if ! python3 -m pip install --help 2>&1 | grep -q \"break-system-packages\"; then
  PIP_FLAGS=\"\"
fi

# Source MPI environment (unified paths for DNF and APT systems)
echo \"Setting up MPI environment...\"
if ! command -v mpicc >/dev/null 2>&1; then
  for d in \
    /usr/lib64/openmpi/bin \
    /usr/lib/openmpi/bin \
    /usr/lib/x86_64-linux-gnu/openmpi/bin \
    /usr/lib/aarch64-linux-gnu/openmpi/bin \
    /opt/openmpi/bin \
    /opt/ompi/bin \
    /usr/local/openmpi/bin; do
    if [ -x \"\$d/mpicc\" ]; then
      export PATH=\"\$d:\$PATH\"
      base=\"\$(dirname \"\$d\")\"
      [ -d \"\$base/lib64\" ] && export LD_LIBRARY_PATH=\"\$base/lib64:\${LD_LIBRARY_PATH:-}\"
      [ -d \"\$base/lib\" ]   && export LD_LIBRARY_PATH=\"\$base/lib:\${LD_LIBRARY_PATH:-}\"
      echo \"Found MPI at: \$d\"
      break
    fi
  done
fi

if ! command -v mpicc >/dev/null 2>&1; then
  echo \"ERROR: mpicc not found in PATH\"
  exit 1
fi

# Verify meson is available
if ! command -v meson >/dev/null 2>&1; then
  echo \"ERROR: meson not found in PATH\"
  echo \"PATH: \$PATH\"
  exit 1
fi

echo \"Found meson: \$(command -v meson)\"

cd \"${ANUGA_DIR}\"
echo \"Building and installing ANUGA...\"
# Use --no-deps since we already installed all dependencies
python3 -m pip install -e . --no-build-isolation --no-deps \$PIP_FLAGS
echo \"ANUGA installation complete.\"
")

add_custom_target(build_anuga
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh
  DEPENDS clone_anuga
  COMMENT "Building and installing ANUGA"
)

# Create MPI environment setup file (unified for DNF and APT)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh
"#!/bin/bash
# Source this file before running ANUGA with MPI
# Compatible with both DNF-based (RHEL/Alma/Fedora) and APT-based (Debian/Ubuntu) systems

# Add user local bin to PATH
export PATH=\"\$HOME/.local/bin:\$PATH\"

if ! command -v mpicc >/dev/null 2>&1; then
  for d in \
    /usr/lib64/openmpi/bin \
    /usr/lib/openmpi/bin \
    /usr/lib/x86_64-linux-gnu/openmpi/bin \
    /usr/lib/aarch64-linux-gnu/openmpi/bin \
    /opt/openmpi/bin \
    /opt/ompi/bin \
    /usr/local/openmpi/bin; do
    if [ -x \"\$d/mpicc\" ]; then
      export PATH=\"\$d:\$PATH\"
      base=\"\$(dirname \"\$d\")\"
      [ -d \"\$base/lib64\" ] && export LD_LIBRARY_PATH=\"\$base/lib64:\${LD_LIBRARY_PATH:-}\"
      [ -d \"\$base/lib\" ]   && export LD_LIBRARY_PATH=\"\$base/lib:\${LD_LIBRARY_PATH:-}\"
      echo \"MPI environment configured: \$d\"
      break
    fi
  done
fi

if command -v mpicc >/dev/null 2>&1; then
  echo \"MPI compiler available: \$(command -v mpicc)\"
else
  echo \"WARNING: mpicc not found in PATH\"
fi
")

# Master setup target
add_custom_target(setup ALL
  DEPENDS clone_anuga build_anuga
  COMMENT "Complete ANUGA setup"
)

# Test target (unified for DNF and APT)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh
"#!/bin/bash
set -e

# Add user local bin to PATH
export PATH=\"\$HOME/.local/bin:\$PATH\"

# Source MPI environment
echo \"Setting up MPI environment for testing...\"
if ! command -v mpicc >/dev/null 2>&1; then
  for d in \
    /usr/lib64/openmpi/bin \
    /usr/lib/openmpi/bin \
    /usr/lib/x86_64-linux-gnu/openmpi/bin \
    /usr/lib/aarch64-linux-gnu/openmpi/bin \
    /opt/openmpi/bin \
    /opt/ompi/bin \
    /usr/local/openmpi/bin; do
    if [ -x \"\$d/mpicc\" ]; then
      export PATH=\"\$d:\$PATH\"
      base=\"\$(dirname \"\$d\")\"
      [ -d \"\$base/lib64\" ] && export LD_LIBRARY_PATH=\"\$base/lib64:\${LD_LIBRARY_PATH:-}\"
      [ -d \"\$base/lib\" ]   && export LD_LIBRARY_PATH=\"\$base/lib:\${LD_LIBRARY_PATH:-}\"
      break
    fi
  done
fi

echo \"\"
echo \"=== Testing ANUGA Installation ===\"
echo \"\"

echo \"[1/4] Testing mpi4py import...\"
python3 -c 'import mpi4py; print(\"✓ mpi4py version:\", mpi4py.__version__)'

echo \"\"
echo \"[2/4] Testing ANUGA import...\"
python3 -c 'import anuga; print(\"✓ ANUGA version:\", anuga.__version__)'

echo \"\"
echo \"[3/4] Testing ANUGA with MPI...\"
python3 -c 'import anuga; from anuga import myid, numprocs; print(\"✓ MPI initialized - myid:\", myid, \"numprocs:\", numprocs)'

echo \"\"
echo \"[4/4] Verifying MPI compiler...\"
if command -v mpicc >/dev/null 2>&1; then
  echo \"✓ MPI compiler: \$(command -v mpicc)\"
  mpicc --version | head -n 1
else
  echo \"✗ WARNING: mpicc not found\"
fi

echo \"\"
echo \"=== All tests passed! ===\"
echo \"\"
echo \"To use ANUGA with MPI in your scripts:\"
echo \"  source ${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\"
echo \"\"
echo \"To run MPI programs:\"
echo \"  mpirun -np 4 python3 your_script.py\"
echo \"\"
")

add_custom_target(test_anuga
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh
  DEPENDS setup
  COMMENT "Testing ANUGA installation"
)

add_custom_target(clean_anuga
  COMMAND ${CMAKE_COMMAND} -E remove_directory ${ANUGA_DIR}
  COMMENT "Removing ANUGA source directory"
)

message(STATUS "")
message(STATUS "========================================")
message(STATUS "ANUGA CMake Configuration Summary")
message(STATUS "========================================")
message(STATUS "Build targets:")
message(STATUS "  make setup         - Clone + build/install ANUGA")
message(STATUS "  make test_anuga    - Test installation")
message(STATUS "  make clean_anuga   - Remove ANUGA source")
message(STATUS "")
message(STATUS "Supports both DNF and APT-based systems")
message(STATUS "========================================")