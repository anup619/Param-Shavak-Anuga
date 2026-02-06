import os

from settings_loader import load_config
from simulation import run_simulation
from bridge import AnugaGeoserverBridge

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    settings_path = os.path.join(script_dir, "settings.toml")

    cfg = load_config(settings_path, script_dir)
    run_simulation(cfg)
    
    try:
        from anuga import myid
    except ImportError:
        myid = 0

    if myid == 0:
        print("\n" + "="*70)
        print("SIMULATION FINISHED. STARTING AUTOMATED DEPLOYMENT...")
        print("="*70)
        
        try:
            bridge = AnugaGeoserverBridge(settings_path, script_dir)
            bridge.run_post_processing(
                target_sww_name=cfg.paths.output_file,
                generate_timeseries=cfg.postprocessing.generate_timeseries
            )
            print("\nDEPLOYMENT COMPLETE. Check your React App.")
        except Exception as e:
            print(f"\nDeployment failed: {e}")
    
    print("Process finished.")

if __name__ == "__main__":
    main()