# Modeler's Manual: Running Simulations & Workflows

This guide explains how to configure, execute, and deploy flood simulations using the ANUGA-GeoServer pipeline. It is intended for researchers and domain experts.

---

## 1. The Configuration Heart: `settings.toml`
Everything about the simulation is controlled here. Before running, open `mahanadi_test_case/settings.toml`.

Key Parameters:
- `[domain]`: Set the `mesh_resolution` (smaller = more detail but slower).
- `[hydrology]`: Define the `manning_n` (friction) and `boundary_conditions`.
- `[simulation]`: Set the `yield_step` (how often to save data) and `final_time`.

---

## 2. Running the Simulation

### Step 1: Initialize the Environment
Always source the MPI environment first to ensure Python sees the correct ANUGA build.
```bash
source build/setup_mpi_env.sh
```

### Step 2: Launch (Sequential vs. Parallel)
For small test cases:
```bash
python3 mahanadi_test_case/simulate.py
```

For large-scale production runs (e.g., 16 cores on Param Shavak):
```bash
mpirun -np 16 python3 mahanadi_test_case/simulate.py
```

## 3. Post-Processing & The Bridge (`bridge.py`)
Once the simulation finishes, it generates a large `.sww` file in `anuga_outputs/.` 
The `bridge.py` script is the "glue" that:
1. Extracts the **Max Depth** (static map).
2. Generates the **Time Series** (tiled sequence).
3. Pushes metadata and styles to **GeoServer**.

## Automation Note:
Usually, `simulate.py` calls `bridge.py` automatically at the end of a run. If you need to re-run the deployment logic without re-running the whole simulation:
```bash
python3 mahanadi_test_case/bridge.py <runid>

#For saving the timeseries file and deploying on geoserver use --timeseries attribute
python3 mahanadi_test_case/bridge.py <runid> --timeseries
```

## 4. Understanding Outputs

| File Type        | Location              | Description                                        |
| :--------------- | :-------------------- | :------------------------------------------------- |
| .sww             | `anuga_outputs/ `     | Raw ANUGA binary output (NetCDF)                   |
| ._max_depth.tif  | `anuga_outputs/ `     | Georeferenced raster for the maximum flood extent. |
| _meta.json       | `anuga_outputs/ `     | Metadata log containing parameters and run time.   |
| _timeseries/     | `anuga_outputs/ `     | Folder containing PNG/TIF slices for animation.    |

## 5. Critical Pitfalls & Checklist
* **GeoServer Status:** If bridge.py fails with a "Connection Refused" error, make sure GeoServer is running 
```bash 
make geoserver-start

# Or
bash build/geoserver_start.sh

# Verify it by
curl -I http://localhost:8080/geoserver

# Should give status [200] or [302]
```

* **Mesh Cache:** If you change the domain boundaries, delete the `mesh_cache/` folder to force ANUGA to regenerate the triangulation.

* **Coordinate Systems**: The pipeline defaults to **UTM Zone 45N (EPSG:32645)** for the Mahanadi region. If modeling a different region, update the projection in both `settings.toml` and `geoserverConfig.`

---
**Next Step:** Once the simulation is deployed to GeoServer, refer to [USER_GUIDE.md](./USER_GUIDE.md)  to visualize the results in the dashboard.