#!/bin/bash
set -euo pipefail

echo "=== ANUGA + Tools setup (ANUGA + MPI + GeoServer + Node + optional anuga-viewer) ==="

# -----------------------------
# sudo handling
# -----------------------------
SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# -----------------------------
# detect package manager
# -----------------------------
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

# -----------------------------
# paths (project-relative)
# -----------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${ROOT_DIR}/opensource_tools"
GEOSERVER_ZIP="${TOOLS_DIR}/geoserver-2.28.2-bin.zip"
GEOSERVER_DIR="${TOOLS_DIR}/geoserver-2.28.2-bin"
NODE_TAR="${TOOLS_DIR}/node-v24.13.0-linux-x64.tar.xz"
NODE_DIR="${TOOLS_DIR}/node-v24.13.0-linux-x64"
VIEWER_DIR="${TOOLS_DIR}/anuga-viewer"

# Optional: allow forcing viewer behavior
#   INSTALL_ANUGA_VIEWER=auto (default) | 0 | 1
INSTALL_ANUGA_VIEWER="${INSTALL_ANUGA_VIEWER:-auto}"

# -----------------------------
# system dependencies
# -----------------------------
echo "Installing system dependencies..."

if [ "$PKG_MGR" = "dnf" ]; then
  $SUDO dnf -y install \
    gcc gcc-c++ make cmake git ninja-build \
    python3 python3-pip python3-devel \
    pkgconf-pkg-config \
    netcdf-devel \
    openmpi openmpi-devel \
    unzip tar curl \
    java-17-openjdk || true

  # Try a newer Java if 17 isn't available (rare, but safe)
  if ! command -v java >/dev/null 2>&1; then
    $SUDO dnf -y install java-latest-openjdk || true
  fi

elif [ "$PKG_MGR" = "apt" ]; then
  $SUDO apt-get update
  $SUDO apt-get install -y \
    gcc g++ make cmake git ninja-build \
    python3 python3-pip python3-dev \
    pkg-config \
    libnetcdf-dev \
    libopenmpi-dev openmpi-bin \
    unzip tar curl \
    default-jre
fi

# -----------------------------
# ensure Java
# -----------------------------
if ! command -v java >/dev/null 2>&1; then
  echo "ERROR: Java not found after install attempt."
  echo "GeoServer needs Java (OpenJDK). Please install OpenJDK via your package manager."
  exit 1
fi
echo "Java OK: $(java -version 2>&1 | head -n 1)"

# -----------------------------
# ensure OpenMPI compilers visible
# -----------------------------
echo "Setting up OpenMPI environment..."
if ! command -v mpicc >/dev/null 2>&1; then
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
  echo "If on HPC: try 'module load mpi/openmpi-x86_64' then rerun."
  exit 1
}

echo "Found MPI compiler: $(command -v mpicc)"
mpicc --version | head -n 1 || true

# -----------------------------
# pip flags (system pip vs conda pip)
# -----------------------------
PY=python3
PIP_FLAGS=""
if $PY -m pip install --help 2>&1 | grep -q "break-system-packages"; then
  # Safe to use on system python; conda ignores/doesn't need it, but it's okay if supported
  PIP_FLAGS="--break-system-packages"
fi

# -----------------------------
# python deps (install ALL dependencies in correct order, once)
# -----------------------------
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

# -----------------------------
# CRITICAL: Build mpi4py with MPI compiler (LAST)
# -----------------------------
echo "Building mpi4py from source with MPI support..."
$PY -m pip uninstall -y mpi4py >/dev/null 2>&1 || true
MPICC="$(command -v mpicc)" $PY -m pip install --no-cache-dir --no-binary mpi4py mpi4py $PIP_FLAGS

echo "Verifying mpi4py installation..."
$PY -c "import mpi4py; print('mpi4py version:', mpi4py.__version__)"

# -----------------------------
# Tooling: GeoServer + Node (local extract; no system install)
# -----------------------------
mkdir -p "$TOOLS_DIR"

echo "Setting up GeoServer..."
if [ -f "$GEOSERVER_ZIP" ]; then
  if [ ! -d "$GEOSERVER_DIR" ]; then
    echo "Unpacking GeoServer from: $GEOSERVER_ZIP"
    unzip -q "$GEOSERVER_ZIP" -d "$GEOSERVER_DIR"
  else
    echo "GeoServer already unpacked at: $GEOSERVER_DIR"
  fi
else
  echo "WARNING: GeoServer zip not found at: $GEOSERVER_ZIP"
  echo "         Skipping GeoServer unpack. Place the zip in opensource_tools/ to enable."
fi

echo "Setting up Node..."
if [ -f "$NODE_TAR" ]; then
  if [ ! -d "$NODE_DIR" ]; then
    echo "Extracting Node from: $NODE_TAR"
    tar -xf "$NODE_TAR" -C "$TOOLS_DIR"
  else
    echo "Node already extracted at: $NODE_DIR"
  fi
else
  echo "WARNING: Node tarball not found at: $NODE_TAR"
  echo "         Skipping Node extract. Place the tar.xz in opensource_tools/ to enable."
fi

# -----------------------------
# Optional: anuga-viewer (best-effort)
# -----------------------------
build_viewer=false
if [ "$INSTALL_ANUGA_VIEWER" = "1" ]; then
  build_viewer=true
elif [ "$INSTALL_ANUGA_VIEWER" = "0" ]; then
  build_viewer=false
else
  # auto mode: build only if deps are available
  build_viewer=true
fi

if $build_viewer; then
  echo "Checking anuga-viewer prerequisites..."
  if [ "$PKG_MGR" = "apt" ]; then
    # straightforward on Ubuntu/Debian
    $SUDO apt-get install -y libgdal-dev libcppunit-dev libopenscenegraph-dev
  else
    # DNF: gdal-devel may not exist on some EL9/HPC mirrors; detect gracefully
    if dnf info gdal-devel >/dev/null 2>&1; then
      $SUDO dnf -y install OpenSceneGraph-devel cppunit-devel gdal-devel
    else
      echo "WARNING: gdal-devel not available in enabled DNF repos."
      echo "         Skipping anuga-viewer build on this machine."
      echo "         (Common on HPC/EL mirrors. Ask admins to provide gdal-devel or a GDAL module.)"
      build_viewer=false
    fi
  fi
fi

if $build_viewer; then
  echo "Setting up anuga-viewer..."
  if [ ! -d "$VIEWER_DIR" ]; then
    git clone https://github.com/GeoscienceAustralia/anuga-viewer.git "$VIEWER_DIR"
  fi

  # Build/install locally (no sudo)
  pushd "$VIEWER_DIR" >/dev/null
  make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
  # Try local prefix install if supported, else fallback to plain make install (may require sudo)
  if make help 2>/dev/null | grep -qi "install"; then
    mkdir -p "$VIEWER_DIR/local"
    make install PREFIX="$VIEWER_DIR/local" 2>/dev/null || make install || true
  fi
  popd >/dev/null
else
  echo "anuga-viewer: skipped."
fi

# -----------------------------
# Build ANUGA via CMake targets
# -----------------------------
echo "Configuring CMake..."
mkdir -p "${ROOT_DIR}/build"
cd "${ROOT_DIR}/build"

cmake .. \
  -DMPI_C_COMPILER="$(command -v mpicc)" \
  -DMPI_CXX_COMPILER="$(command -v mpicxx 2>/dev/null || command -v mpic++ 2>/dev/null || echo '')"

echo "Building ANUGA..."
make setup

# -----------------------------
# Generate unified env scripts in build/
# -----------------------------
echo "Generating environment helper scripts..."

# tools env
cat > "${ROOT_DIR}/build/setup_tools_env.sh" << EOF
#!/bin/bash
# Source this before using Node/GeoServer/anuga-viewer (if installed)

# User local bin (meson, etc.)
export PATH="\$HOME/.local/bin:\$PATH"

# Node (local bundle)
if [ -d "${NODE_DIR}" ]; then
  export NODE_HOME="${NODE_DIR}"
  export PATH="\$NODE_HOME/bin:\$PATH"
fi

# GeoServer (local bundle)
if [ -d "${GEOSERVER_DIR}" ]; then
  export GEOSERVER_HOME="${GEOSERVER_DIR}"
fi

# anuga-viewer (if built locally)
if [ -d "${VIEWER_DIR}/local/bin" ]; then
  export SWOLLEN_BINDIR="${VIEWER_DIR}/local/bin"
  export PATH="\$PATH:\$SWOLLEN_BINDIR"
elif [ -d "${VIEWER_DIR}/bin" ]; then
  export SWOLLEN_BINDIR="${VIEWER_DIR}/bin"
  export PATH="\$PATH:\$SWOLLEN_BINDIR"
fi

echo "Tools environment configured."
echo "NODE_HOME=\${NODE_HOME:-}"
echo "GEOSERVER_HOME=\${GEOSERVER_HOME:-}"
echo "SWOLLEN_BINDIR=\${SWOLLEN_BINDIR:-}"
EOF
chmod +x "${ROOT_DIR}/build/setup_tools_env.sh"

# geoserver start/stop convenience
cat > "${ROOT_DIR}/build/geoserver_start.sh" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/setup_tools_env.sh" >/dev/null 2>&1 || true
if [ -z "\${GEOSERVER_HOME:-}" ]; then
  echo "ERROR: GEOSERVER_HOME not set (GeoServer not installed/unpacked)."
  exit 1
fi
cd "\$GEOSERVER_HOME/bin"
nohup bash startup.sh > "\$GEOSERVER_HOME/../geoserver.out" 2>&1 &
echo "GeoServer starting (detached). Log: \$GEOSERVER_HOME/../geoserver.out"
EOF
chmod +x "${ROOT_DIR}/build/geoserver_start.sh"

cat > "${ROOT_DIR}/build/geoserver_stop.sh" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/setup_tools_env.sh" >/dev/null 2>&1 || true
if [ -z "\${GEOSERVER_HOME:-}" ]; then
  echo "ERROR: GEOSERVER_HOME not set (GeoServer not installed/unpacked)."
  exit 1
fi
cd "\$GEOSERVER_HOME/bin"
bash shutdown.sh || true
echo "GeoServer stop requested."
EOF
chmod +x "${ROOT_DIR}/build/geoserver_stop.sh"

echo ""
echo "=== DONE ==="
echo ""
echo "ANUGA test:"
echo "  cd build && make test_anuga"
echo ""
echo "Use tools (Node/GeoServer):"
echo "  source build/setup_tools_env.sh"
echo "  node -v"
echo "  bash build/geoserver_start.sh"
echo "  curl -I http://localhost:8080/geoserver"
echo "  bash build/geoserver_stop.sh"
echo ""
echo "Use ANUGA with MPI:"
echo "  source build/setup_mpi_env.sh"
echo "  mpirun -np 4 python3 <parallel_simulation>.py"
echo ""
echo "If anuga-viewer was built:"
echo "  source build/setup_tools_env.sh"
echo "  anuga_viewer <file.sww>"
echo ""