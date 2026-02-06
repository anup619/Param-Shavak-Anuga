import os
import sys
import datetime
import requests
from requests.auth import HTTPBasicAuth
import anuga
from settings_loader import load_config
from logger import log_run_metadata

class AnugaGeoserverBridge:
    def __init__(self, settings_path: str, script_dir: str):
        self.cfg = load_config(settings_path, script_dir)
        self.gs_url = "http://localhost:8080/geoserver/rest"
        self.auth = HTTPBasicAuth("admin", "geoserver")
        self.workspace = "anuga"
        
        self.target_layer = "mahanadi_dam_release_max_depth"
        self.store_name = "mahanadi_max_depth_store"

    def run_post_processing(self, target_sww_name: str):
        run_id = target_sww_name if target_sww_name else self.cfg.paths.output_file
        sww_path = os.path.join(self.cfg.paths.output_dir, f"{run_id}.sww")
        
        asc_path = os.path.join(self.cfg.paths.output_dir, f"{run_id}_max_depth.asc")
        
        print(f"--- Starting Post-Processing for: {run_id} ---")
        
        if not os.path.exists(sww_path):
            print(f"Error: Source file not found: {sww_path}")
            return
        
        print(f"Converting {run_id}.sww to ASCII Grid...")
        try:
            anuga.sww2dem(
                sww_path, 
                asc_path, 
                quantity='depth', 
                reduction=max, 
                cellsize=10
            )
        except Exception as e:
            print(f" ANUGA sww2dem failed: {e}")
            return

        print(f"Deploying ASCII Grid to GeoServer...")
        try:
            # Use run_id to create unique store and layer names
            self.deploy_to_geoserver(asc_path, run_id)
        except Exception as e:
            print(f" X GeoServer Deployment failed: {e}")
            
        log_run_metadata(self.cfg, run_id) 

        print(f"--- Finished. Result saved as: {os.path.basename(asc_path)} ---")
        print(f"Check your React dashboard for layer: {run_id}")

    def deploy_to_geoserver(self, file_path, run_id):
        filename = os.path.basename(file_path)
        is_asc = file_path.lower().endswith('.asc')
        
        # Create unique names for this run
        store_name = f"{run_id}_store"
        layer_name = f"{run_id}_max_depth"
        
        if is_asc:
            content_type = "application/arcgrid"
            format_type = "arcgrid"
        else:
            content_type = "image/geotiff"
            format_type = "geotiff"

        print(f"Deploying {filename} to GeoServer workspace: {self.workspace} (Format: {format_type})...")

        requests.post(f"{self.gs_url}/workspaces", json={"workspace": {"name": self.workspace}}, auth=self.auth)
        
        upload_url = (
            f"{self.gs_url}/workspaces/{self.workspace}/"
            f"coveragestores/{store_name}/file.{format_type}"
            f"?configure=first&coverageName={layer_name}"
        )
        
        with open(file_path, "rb") as f:
            resp = requests.put(
                upload_url,
                data=f,
                headers={"Content-type": content_type},
                auth=self.auth
            )

        if resp.status_code in [200, 201]:
            print(f"SUCCESS: Coverage uploaded. Now updating SRS to EPSG:32645...")
            
            # Update the coverage to fix SRS
            coverage_url = f"{self.gs_url}/workspaces/{self.workspace}/coveragestores/{store_name}/coverages/{layer_name}.json"
            
            coverage_data = {
                "coverage": {
                    "srs": "EPSG:32645",
                    "nativeCRS": "EPSG:32645",
                    "projectionPolicy": "REPROJECT_TO_DECLARED",
                    "requestSRS": {
                        "string": ["EPSG:32645", "EPSG:3857", "EPSG:4326"]
                    },
                    "responseSRS": {
                        "string": ["EPSG:32645", "EPSG:3857", "EPSG:4326"]
                    }
                }
            }
            
            update_resp = requests.put(
                coverage_url,
                json=coverage_data,
                headers={"Content-type": "application/json"},
                auth=self.auth
            )
            
            if update_resp.status_code == 200:
                print(f"SUCCESS: Layer '{self.workspace}:{layer_name}' configured with EPSG:32645")
            else:
                print(f"WARNING: SRS update responded with {update_resp.status_code}: {update_resp.text}")
        else:
            print(f"ERROR: GeoServer responded with {resp.status_code}: {resp.text}")

if __name__ == "__main__":
    # Usage: python3 bridge.py mahanadi_dam_release_20260205_1148
    current_dir = os.path.dirname(os.path.abspath(__file__))
    settings = os.path.join(current_dir, "settings.toml")
    
    bridge = AnugaGeoserverBridge(settings, current_dir)
    if len(sys.argv) > 1:
        manual_name = sys.argv[1]
        bridge.run_post_processing(target_sww_name=manual_name)
    else:
        bridge.run_post_processing()