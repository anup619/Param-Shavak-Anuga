cmake_minimum_required(VERSION 3.15)
project(ANUGA_Setup)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use the exact Python that CMake finds (prevents "installed to wrong python" issues,
# especially when conda is active)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

find_package(PkgConfig REQUIRED)
message(STATUS "Checking for required system packages...")

# GDAL (OPTIONAL) - only used for optional tooling (e.g., anuga-viewer), not required for ANUGA core
pkg_check_modules(GDAL gdal)
if(GDAL_FOUND)
  message(STATUS "Found GDAL: ${GDAL_VERSION}")
else()
  message(STATUS "GDAL not found (ok). Some GIS features (optional tools) will be unavailable.")
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

# -----------------------------
# Paths
# -----------------------------
set(ANUGA_DIR "${CMAKE_CURRENT_SOURCE_DIR}/anuga_core")
set(TOOLS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/opensource_tools")

# -----------------------------
# Clone ANUGA repository (idempotent)
# -----------------------------
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/clone_anuga.sh
"#!/bin/bash
set -euo pipefail
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

# -----------------------------
# Write MPI env helper (single source of truth for PATH/LD_LIBRARY_PATH)
# NOTE: This does NOT install anything. setup.sh is responsible for installs.
# -----------------------------
set(MPI_ENV_CONTENT "#!/bin/bash
# Source this file before running ANUGA with MPI
# Compatible with both DNF-based (RHEL/Alma/Fedora) and APT-based (Debian/Ubuntu) systems

# Add user local bin to PATH (meson, etc.)
export PATH=\"\$HOME/.local/bin:\$PATH\"

# Try to locate MPI compiler if not already visible
if ! command -v mpicc >/dev/null 2>&1\; then
  for d in \\
    /usr/lib64/openmpi/bin \\
    /usr/lib/openmpi/bin \\
    /usr/lib/x86_64-linux-gnu/openmpi/bin \\
    /usr/lib/aarch64-linux-gnu/openmpi/bin \\
    /opt/openmpi/bin \\
    /opt/ompi/bin \\
    /usr/local/openmpi/bin\; do
    if [ -x \"\$d/mpicc\" ]\; then
      export PATH=\"\$d:\$PATH\"
      base=\"\$(dirname \"\$d\")\"
      [ -d \"\$base/lib64\" ] && export LD_LIBRARY_PATH=\"\$base/lib64:\${LD_LIBRARY_PATH:-}\"
      [ -d \"\$base/lib\" ]   && export LD_LIBRARY_PATH=\"\$base/lib:\${LD_LIBRARY_PATH:-}\"
      echo \"MPI environment configured: \$d\"
      break
    fi
  done
fi

if command -v mpicc >/dev/null 2>&1\; then
  echo \"MPI compiler available: \$(command -v mpicc)\"
else
  echo \"WARNING: mpicc not found in PATH\"
fi
")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh "${MPI_ENV_CONTENT}")

# Create a custom target to ensure this file is written
add_custom_target(write_env
  COMMAND ${CMAKE_COMMAND} -E echo "MPI environment script written"
  COMMENT "Writing MPI environment setup script"
)

# -----------------------------
# Build/install ANUGA (no deps here)
# - setup.sh installs dependencies (python wheels, mpi4py, etc)
# - this only installs anuga_core editable into the SAME Python interpreter
# -----------------------------
set(BUILD_ANUGA_CONTENT "#!/bin/bash
set -euo pipefail

# Ensure user local bin visible (meson/cython sometimes live here)
export PATH=\"\$HOME/.local/bin:\$PATH\"

# Use the exact Python interpreter resolved by CMake
PY=\"${Python3_EXECUTABLE}\"

# Prefer the env script we generate (single source of truth)
if [ -f \"${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\" ]
then
  source \"${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\" >/dev/null 2>&1 || true
fi

if ! command -v mpicc >/dev/null 2>&1
then
  echo \"ERROR: mpicc not found in PATH\"
  exit 1
fi

# Sanity checks
if ! command -v meson >/dev/null 2>&1
then
  echo \"ERROR: meson not found in PATH (run setup.sh first)\"
  exit 1
fi

cd \"${ANUGA_DIR}\"
echo \"Building and installing ANUGA into: \$(${Python3_EXECUTABLE} -c 'import sys; print(sys.executable)')\"
# --no-deps because setup.sh already installed all deps.
# --no-build-isolation so it uses already-installed build deps.
\"\$PY\" -m pip install -e . --no-build-isolation --no-deps
echo \"ANUGA installation complete.\"
")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh "${BUILD_ANUGA_CONTENT}")

add_custom_target(build_anuga
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/build_anuga.sh
  DEPENDS clone_anuga write_env
  COMMENT "Installing ANUGA (editable, no deps)"
)

# -----------------------------
# Test ANUGA (no installing here)
# -----------------------------
set(TEST_ANUGA_CONTENT "#!/bin/bash
set -euo pipefail

export PATH=\"\$HOME/.local/bin:\$PATH\"
PY=\"${Python3_EXECUTABLE}\"

# Source MPI environment (so mpicc + LD_LIBRARY_PATH are correct)
if [ -f \"${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\" ]\; then
  source \"${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\" >/dev/null 2>&1 || true
fi

echo \"\"
echo \"=== Testing ANUGA Installation ===\"
echo \"\"

echo \"[1/4] Testing mpi4py import...\"
\"\$PY\" -c 'import mpi4py\; print(\"✓ mpi4py version:\", mpi4py.__version__)'

echo \"\"
echo \"[2/4] Testing ANUGA import...\"
\"\$PY\" -c 'import anuga\; print(\"✓ ANUGA version:\", anuga.__version__)'

echo \"\"
echo \"[3/4] Testing ANUGA MPI init view (ANUGA decides sequential vs MPI)...\"
\"\$PY\" -c 'import anuga\; from anuga import myid, numprocs\; print(\"✓ myid:\", myid, \"numprocs:\", numprocs)'

echo \"\"
echo \"[4/4] Verifying MPI compiler...\"
if command -v mpicc >/dev/null 2>&1\; then
  echo \"✓ MPI compiler: \$(command -v mpicc)\"
  mpicc --version | head -n 1 || true
else
  echo \"✗ WARNING: mpicc not found\"
fi

echo \"\"
echo \"=== Tests completed ===\"
echo \"\"
echo \"To use ANUGA with MPI in your scripts:\"
echo \"  source ${CMAKE_CURRENT_BINARY_DIR}/setup_mpi_env.sh\"
echo \"\"
")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh "${TEST_ANUGA_CONTENT}")

add_custom_target(test_anuga
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/test_anuga.sh
  DEPENDS build_anuga
  COMMENT "Testing ANUGA installation"
)

# -----------------------------
# Optional: Toolchain checks (Node/GeoServer env created by setup.sh)
# This does NOT install tools\; it just verifies they are visible when env is sourced.
# -----------------------------
set(TEST_TOOLS_CONTENT "#!/bin/bash
set -euo pipefail

# setup.sh generates build/setup_tools_env.sh (sibling to this build dir)
if [ -f \"${CMAKE_CURRENT_BINARY_DIR}/setup_tools_env.sh\" ]\; then
  source \"${CMAKE_CURRENT_BINARY_DIR}/setup_tools_env.sh\" >/dev/null 2>&1 || true
fi

echo \"\"
echo \"=== Testing Tools (best effort) ===\"
echo \"\"

if command -v node >/dev/null 2>&1\; then
  echo \"✓ Node: \$(node -v)\"
else
  echo \"⚠ Node not on PATH (expected if Node tarball not provided/extracted)\"
fi

if [ -n \"\${GEOSERVER_HOME:-}\" ] && [ -d \"\$GEOSERVER_HOME\" ]\; then
  echo \"✓ GEOSERVER_HOME=\$GEOSERVER_HOME\"
  [ -x \"\$GEOSERVER_HOME/bin/startup.sh\" ] && echo \"✓ GeoServer startup.sh present\"
else
  echo \"⚠ GeoServer not configured (expected if zip not provided/unpacked)\"
fi

echo \"\"
echo \"=== Tool checks done ===\"
echo \"\"
")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/test_tools.sh "${TEST_TOOLS_CONTENT}")

add_custom_target(test_tools
  COMMAND chmod +x ${CMAKE_CURRENT_BINARY_DIR}/test_tools.sh
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/test_tools.sh
  COMMENT "Testing Node/GeoServer environment (no installs)"
)

# -----------------------------
# Master setup target (NO 'ALL' to avoid surprise builds)
# -----------------------------
add_custom_target(setup
  DEPENDS build_anuga
  COMMENT "Complete ANUGA setup (clone + editable install)"
)

# -----------------------------
# Clean ANUGA source dir (optional)
# -----------------------------
add_custom_target(clean_anuga
  COMMAND ${CMAKE_COMMAND} -E remove_directory ${ANUGA_DIR}
  COMMENT "Removing ANUGA source directory"
)

message(STATUS "")
message(STATUS "========================================")
message(STATUS "ANUGA CMake Configuration Summary")
message(STATUS "========================================")
message(STATUS "Python interpreter: ${Python3_EXECUTABLE}")
message(STATUS "Build targets:")
message(STATUS "  make setup         - Clone + editable install ANUGA (no deps)")
message(STATUS "  make test_anuga    - Test installation")
message(STATUS "  make test_tools    - Best-effort tool checks (Node/GeoServer env)")
message(STATUS "  make clean_anuga   - Remove ANUGA source")
message(STATUS "")
message(STATUS "Note: setup.sh installs dependencies and may generate setup_tools_env.sh in build/.")
message(STATUS "========================================")