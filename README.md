# Param Shavak ANUGA | HPC-in-a-Box Flood Simulation System

## Overview

Param Shavak ANUGA is a **plug-and-play flood simulation pipeline** designed to run on HPC systems or powerful Linux workstations.

It packages the full workflow into one reproducible environment:

- ANUGA flood simulation engine (MPI parallel capable)
- Automated post-processing pipeline
- GeoServer map publishing
- React dashboard visualization
- Optional 3D ANUGA viewer

The goal is simple:
Run one install → run simulation → visualize results.

---

## Who This Repository Is For

### HPC / System Administrators
Responsible for installing dependencies and setting up environment.

➡ Read: `INSTALL.md`

---

### Flood Modelers / Researchers
Responsible for configuring simulations and generating outputs.

➡ Read: `RUNNING.md`

---

### Stakeholders / Dashboard Users
Responsible only for viewing flood outputs on dashboard.

➡ Read: `USER_GUIDE.md`

---

## First Time Setup (Golden Path)

### Step 0 — Clone Repository

```bash
git clone https://github.com/anup619/Param-Shavak-Anuga

cd Param-Shavak-Anuga
git lfs pull
```

Run `git lfs pull` **only first time** or if large files are missing.

All commands in docs assume you are inside repo root directory.

---

### Step 1 — Install Full Stack
```bash
make setup
```

This installs:
- System dependencies
- Python scientific stack
- MPI + mpi4py
- ANUGA core
- GeoServer (if archive present)
- Node.js (if archive present)

---

### Step 2 — Run Simulation

```bash
source build/setup_mpi_env.sh
mpirun -np 16 python3 mahanadi_test_case/simulate.py
```

---

### Step 3 — Start Visualization
```bash
make geoserver-start
source build/setup_tools_env.sh
cd anuga-viewer-app
npm run dev
```
Dashboard runs at:
`http://localhost:5173`

---

## How The Pipeline Works
```
Install → Configure → Simulate → Postprocess → Deploy → Visualize
```

Detailed behavior:
- `setup.sh` installs system + python dependencies
- CMake installs ANUGA locally
- Simulation produces `.sww`
- bridge.py converts outputs + deploys to GeoServer
- React dashboard reads WMS layers

---

## Repository Structure
```plaintext
Param-Shavak-Anuga/
│
├ INSTALL.md
├ RUNNING.md
├ USER_GUIDE.md
│
├ build/
│ ├ setup_mpi_env.sh
│ ├ setup_tools_env.sh
│ ├ geoserver_start.sh
│ └ geoserver_stop.sh
│
├ opensource_tools/
│ ├ geoserver-.zip
│ └ node-.tar.xz
│
├ anuga_core/
│
└ mahanadi_test_case/
```

---

## When To Read Which File

| Situation | Read |
|---|---|
| First time installation | INSTALL.md |
| Running flood simulation | RUNNING.md |
| Viewing dashboard results | USER_GUIDE.md |

---

## Plug-and-Play Philosophy

This system is designed so that:

Admin installs once  
Modelers run simulations  
Stakeholders view results  

No manual dependency chasing.

---

## Support / Contact

Anup Bagde  
Project Engineer - HPC ESEG Group  
CDAC Pune  
Email: anupb@cdac.in

---