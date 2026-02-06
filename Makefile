# Makefile wrapper for ANUGA CMake build system

.PHONY: all setup install test clean clean-all help test_anuga verify

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

verify:
	@echo "Verifying ANUGA installation..."
	@if [ ! -f build/setup_mpi_env.sh ]; then \
		echo "ERROR: build/setup_mpi_env.sh not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@bash -c "source build/setup_mpi_env.sh && python3 -c 'import anuga; print(\"ANUGA version:\", anuga.__version__)'"
	@echo "✓ ANUGA is properly installed and importable"

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
		echo "React App Node module remover removed."; \
	fi
	@echo "Complete cleanup done (build, source, opensourcetools, nodemodule and simulation outputs)."



help:
	@echo "ANUGA Build System - Available targets:"
	@echo ""
	@echo "  make setup         - Install all dependencies and build ANUGA (default)"
	@echo "  make install       - Alias for setup"
	@echo "  make test          - Test ANUGA installation"
	@echo "  make verify        - Quick verification that ANUGA can be imported"
	@echo "  make clean         - Remove build directory"
	@echo "  make clean-outputs - Remove simulation outputs (mesh_cache, anuga_outputs)"
	@echo "  make clean-all     - Remove everything (build, source, and outputs)"
	@echo "  make help          - Show this help message"
	@echo ""
	@echo "After installation, before running ANUGA scripts:"
	@echo "  source build/setup_mpi_env.sh"
	@echo ""
	@echo "Example workflow:"
	@echo "  make setup         # First time setup"
	@echo "  make verify        # Verify installation"
	@echo "  make test          # Run full test suite"
	@echo ""
	@echo "Cleanup workflow:"
	@echo "  make clean-outputs # Clean only simulation outputs"
	@echo "  make clean-all     # Complete cleanup including source"