# User Guide: Visualizing Flood Results

This guide is for end-users and stakeholders who need to access the dashboard and interpret the flood simulation results. No technical or programming knowledge is required.

---

## 1. Quick Start: Launching the Dashboard

Before you can see the maps, the background services must be running. If the IT team has already set this up, you can skip to Step 3.

### Step 1: Start the Map Server
```bash
make geoserver-start

# Or
bash build/geoserver_start.sh

# Verify it by
curl -I http://localhost:8080/geoserver

# Should give status [200] or [302]
```
### Step 2: Start the Web Dashboard
```bash
source build/setup_tools_env.sh

# Navigate to your react app folder
cd anuga-viewer-app

# start the react app
npm run dev

```
React app will be started at `http://localhost:5173/`

### Step 3: Open your Browser
Navigate to: `http://localhost:5173/`

## 2. Using the Dashboard

### Layer Control (Right Panel)
* **Max Depth Layers:** Select a specific simulation run to see the "Worst Case Scenario." This shows the highest level the water reached at every point.
* **Time Series Layers:** Select this to see how the flood evolved over time (e.g., from the moment of dam release to 24 hours later).

### The Time Slider
When a "Time Series" layer is active, a slider will appear at the top.
* **Drag the slider** to move forward or backward in time.
* Each step represents a specific interval (e.g., 30 minutes) defined during the simulation.

### Navigation
* **Zoom:** Use your mouse wheel or the +/- buttons.
* **Pan:** Click and drag to move around the Mahanadi basin.
* **Auto-Center:** The map will automatically jump to the relevant area whenever you select a new layer.

## 3. How to Read the Map (The Legend)
The colors on the map indicate the depth of the water.

| Color    | Depth        | Interpretation                                                |
| :--------| :----------- | :------------------------------------------------------------ |
| Yellow   | 0.01m - 0.2m | Very shallow. Safe for most vehicles.                         |
| Orange   | 0.5m - 1.0m  | Moderate. Dangerous for small cars; entering buildings.       |
| Red      | 2.0m - 3.5m  | Severe. Dangerous for people; ground floors submerged.        |
| Deep Red | 5.0m - 10m+  | Catastrophic. Structural damage likely; evacuation mandatory. |

***Note: Areas with no color are considered "Dry" or unaffected by the flood scenario.***

## 4. Common Questions
#### Why is the map blank?
* Ensure you have clicked on a layer name in the right-hand panel.
* Wait a few seconds for the "Loading..." indicator to disappear; high-resolution maps can take a moment to fetch from the server.
#### The time slider isn't moving the water.
* Make sure you have a "Time Series" layer selected, not a "Max Depth" layer. Max Depth is a static image and does not change with time.

**Support:** For technical issues or any help contact \
Anup Bagde \
Project Engineer, HPC-ESEG Group \
CDAC - Pune. \
***anupb@cdac.in***