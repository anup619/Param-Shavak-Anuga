#!/bin/bash
set -euo pipefail

echo "=== ANUGA setup (Universal: DNF and APT support) ==="

# --- sudo handling ---
SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# --- detect package manager ---
if command -v dnf >/dev/null 2>&1; then
  PKG_MGR="dnf"
  echo "Detected package manager: DNF"
elif command -v apt-get >/dev/null 2>&1; then
  PKG_MGR="apt"
  echo "Detected package manager: APT"
else
  echo "ERROR: Neither dnf nor apt-get found. Unsupported system."
  exit 1
fi

# --- install system dependencies based on package manager ---
echo "Installing system dependencies..."
if [ "$PKG_MGR" = "dnf" ]; then
  # DNF/RHEL/Alma/Fedora packages
  $SUDO dnf -y install \
    gcc gcc-c++ make cmake git ninja-build \
    python3 python3-pip python3-devel \
    pkgconf-pkg-config \
    netcdf-devel \
    openmpi openmpi-devel || \
  $SUDO dnf -y install \
    gcc gcc-c++ make cmake git ninja-build \
    python3 python3-pip python3-devel \
    pkgconfig \
    netcdf-devel \
    openmpi openmpi-devel

elif [ "$PKG_MGR" = "apt" ]; then
  # APT/Debian/Ubuntu packages
  $SUDO apt-get update
  $SUDO apt-get install -y \
    gcc g++ make cmake git ninja-build \
    python3 python3-pip python3-dev \
    pkg-config \
    libnetcdf-dev \
    libopenmpi-dev openmpi-bin
fi

# --- ensure OpenMPI compilers are visible ---
echo "Setting up OpenMPI environment..."
if ! command -v mpicc >/dev/null 2>&1; then
  # Common OpenMPI paths for both DNF and APT systems
  for d in \
    /usr/lib64/openmpi/bin \
    /usr/lib/openmpi/bin \
    /usr/lib/x86_64-linux-gnu/openmpi/bin \
    /usr/lib/aarch64-linux-gnu/openmpi/bin \
    /opt/openmpi/bin \
    /opt/ompi/bin \
    /usr/local/openmpi/bin; do
    if [ -x "$d/mpicc" ]; then
      export PATH="$d:$PATH"
      base="$(dirname "$d")"
      [ -d "$base/lib64" ] && export LD_LIBRARY_PATH="$base/lib64:${LD_LIBRARY_PATH:-}"
      [ -d "$base/lib" ]   && export LD_LIBRARY_PATH="$base/lib:${LD_LIBRARY_PATH:-}"
      break
    fi
  done
fi

command -v mpicc >/dev/null 2>&1 || { 
  echo "ERROR: mpicc not found. OpenMPI is installed but not accessible in PATH."
  echo "Try: module load mpi/openmpi (if using environment modules)"
  exit 1
}

echo "Found MPI compiler: $(command -v mpicc)"
echo "MPI compiler version:"
mpicc --version | head -n 1

# --- Determine pip install flags based on system ---
PY=python3
PIP_FLAGS="--break-system-packages"

# Check if we need --break-system-packages (Ubuntu 23.04+, Debian 12+, Fedora 38+)
if $PY -m pip install --help 2>&1 | grep -q "break-system-packages"; then
  echo "Using --break-system-packages flag for pip installations"
else
  PIP_FLAGS=""
fi

# --- python deps (install ALL dependencies in correct order, once) ---
echo "Upgrading pip and setuptools..."
$PY -m pip install --upgrade pip setuptools wheel $PIP_FLAGS

echo "Installing build dependencies..."
$PY -m pip install --upgrade \
  cython \
  meson meson-python ninja \
  $PIP_FLAGS

echo "Installing scientific computing stack..."
$PY -m pip install --upgrade \
  numpy scipy matplotlib tomli \
  $PIP_FLAGS

echo "Installing geospatial and I/O libraries..."
$PY -m pip install --upgrade \
  netcdf4 pyshp \
  $PIP_FLAGS

echo "Installing ANUGA-specific dependencies..."
$PY -m pip install --upgrade \
  dill pymetis pytools polyline triangle \
  $PIP_FLAGS

# --- CRITICAL: Build mpi4py with MPI compiler (LAST, after all other deps) ---
echo "Building mpi4py from source with MPI support..."
# Remove any existing mpi4py to ensure clean build
$PY -m pip uninstall -y mpi4py || true
# Build from source with MPI compiler
MPICC=$(command -v mpicc) $PY -m pip install --no-cache-dir --no-binary mpi4py mpi4py $PIP_FLAGS

echo "Verifying mpi4py installation..."
$PY -c "import mpi4py; print('mpi4py version:', mpi4py.__version__)"
echo "All Python dependencies installed successfully."

# --- build ---
echo "Configuring CMake..."
mkdir -p build
cd build
cmake .. \
  -DMPI_C_COMPILER="$(command -v mpicc)" \
  -DMPI_CXX_COMPILER="$(command -v mpicxx 2>/dev/null || command -v mpic++ 2>/dev/null || echo '')"

echo "Building ANUGA (installing without re-downloading dependencies)..."
make setup

echo ""
echo "=== DONE ==="
echo ""
echo "To test the installation:"
echo "  cd build && make test_anuga"
echo ""
echo "Or manually:"
echo "  source build/setup_mpi_env.sh"
echo "  python3 -c 'import anuga; print(anuga.__version__)'"
echo ""
echo "To run ANUGA with MPI (4 processes):"
echo "  source build/setup_mpi_env.sh"
echo "  mpirun -np 4 python3 <parallel_simulation>.py"
echo ""