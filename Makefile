# Makefile wrapper for ANUGA setup.sh + CMake build targets

.PHONY: all setup install test test_anuga test_tools verify geoserver-start geoserver-stop \
        clean clean-outputs clean-opensourcetools clean-all help

all: setup

setup:
	@echo "Running automated setup..."
	@if [ ! -f setup.sh ]; then \
		echo "ERROR: setup.sh not found in current directory"; \
		exit 1; \
	fi
	@chmod +x setup.sh
	@./setup.sh

install: setup

test: test_anuga

test_anuga:
	@echo "Testing ANUGA installation..."
	@if [ ! -d build ]; then \
		echo "ERROR: build directory not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@cd build && $(MAKE) test_anuga

test_tools:
	@echo "Testing toolchain (best effort: Node/GeoServer)..."
	@if [ ! -d build ]; then \
		echo "ERROR: build directory not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@cd build && $(MAKE) test_tools

verify:
	@echo "Quick verify (ANUGA import using build/test script)..."
	@if [ ! -f build/test_anuga.sh ]; then \
		echo "ERROR: build/test_anuga.sh not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@bash build/test_anuga.sh >/dev/null 2>&1 || true
	@bash -c "source build/setup_mpi_env.sh >/dev/null 2>&1 || true; python3 -c 'import anuga; print(\"ANUGA version:\", anuga.__version__)'"
	@echo "✓ ANUGA is importable (basic check)"

geoserver-start:
	@echo "Starting GeoServer (detached)..."
	@if [ ! -f build/geoserver_start.sh ]; then \
		echo "ERROR: build/geoserver_start.sh not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@bash build/geoserver_start.sh

geoserver-stop:
	@echo "Stopping GeoServer..."
	@if [ ! -f build/geoserver_stop.sh ]; then \
		echo "ERROR: build/geoserver_stop.sh not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@bash build/geoserver_stop.sh

clean:
	@echo "Cleaning build directory..."
	@if [ -d build ]; then \
		rm -rf build/; \
		echo "Build directory removed."; \
	else \
		echo "Build directory does not exist (already clean)."; \
	fi

clean-outputs:
	@echo "Cleaning ANUGA simulation outputs..."
	@if [ -d mahanadi_test_case/mesh_cache ]; then \
		rm -rf mahanadi_test_case/mesh_cache/*; \
		echo "Cleared mesh_cache directory."; \
	else \
		echo "mesh_cache directory does not exist."; \
	fi
	@if [ -d mahanadi_test_case/anuga_outputs ]; then \
		rm -rf mahanadi_test_case/anuga_outputs/*; \
		echo "Cleared anuga_outputs directory."; \
	else \
		echo "anuga_outputs directory does not exist."; \
	fi
	@if [ -d mahanadi_test_case/__pycache__ ]; then \
		rm -rf mahanadi_test_case/__pycache__; \
		echo "Cleared __pycache__ directory."; \
	fi
	@if [ -f mahanadi_test_case/anuga_pmesh_gui.log ]; then \
		rm -rf mahanadi_test_case/anuga_pmesh_gui.log; \
		echo "Cleared anuga_pmesh_gui.log."; \
	fi
	@echo "Simulation outputs cleaned."

clean-opensourcetools:
	@echo "Removing OpenSourceTools..."
	@if [ -d opensource_tools/geoserver-2.28.2-bin ]; then \
		rm -rf opensource_tools/geoserver-2.28.2-bin/ ; \
		echo "Geoserver removed."; \
	fi
	@if [ -d opensource_tools/node-v24.13.0-linux-x64 ]; then \
		rm -rf opensource_tools/node-v24.13.0-linux-x64/ ; \
		echo "Node removed."; \
	fi
	@if [ -d opensource_tools/anuga-viewer ]; then \
		rm -rf opensource_tools/anuga-viewer/ ; \
		echo "Anuga Viewer removed."; \
	fi
	@echo "OpenSourceTools cleaned (geoserver, node, and anuga-viewer)."

clean-all: clean clean-outputs clean-opensourcetools
	@echo "Removing ANUGA source..."
	@if [ -d anuga_core ]; then \
		rm -rf anuga_core/; \
		echo "ANUGA source removed."; \
	else \
		echo "ANUGA source directory does not exist."; \
	fi
	@if [ -d anuga-viewer-app/node_modules ]; then \
		rm -rf anuga-viewer-app/node_modules/; \
		echo "React App node_modules removed."; \
	fi
	@echo "Complete cleanup done (build, source, opensourcetools, node_modules, outputs)."

help:
	@echo "ANUGA Build System - Available targets:"
	@echo ""
	@echo "  make setup            - Install deps + build ANUGA + unpack tools (default)"
	@echo "  make install          - Alias for setup"
	@echo "  make test             - Run ANUGA tests"
	@echo "  make test_tools        - Best-effort checks for Node/GeoServer env"
	@echo "  make verify            - Quick import sanity check"
	@echo "  make geoserver-start   - Start GeoServer (detached)"
	@echo "  make geoserver-stop    - Stop GeoServer"
	@echo "  make clean             - Remove build directory"
	@echo "  make clean-outputs      - Remove simulation outputs (mesh_cache, anuga_outputs)"
	@echo "  make clean-opensourcetools - Remove unpacked tools (geoserver/node/anuga-viewer)"
	@echo "  make clean-all          - Remove everything (build, source, tools, outputs)"
	@echo ""
	@echo "After installation:"
	@echo "  source build/setup_mpi_env.sh"
	@echo "  source build/setup_tools_env.sh"