import { useEffect, useRef, useState } from "react";
import { Map, View } from "ol";
import TileLayer from "ol/layer/Tile";
import ImageLayer from "ol/layer/Image";
import OSM from "ol/source/OSM";
import ImageWMS from "ol/source/ImageWMS";
import { transformExtent } from "ol/proj";

import { geoserverConfig } from "../config/geoserverConfig";
import { fetchAvailableLayers } from "../services/geoserverService";

import "ol/ol.css";

const MapComponent = () => {
  const mapRef = useRef(null);
  const wmsLayerRef = useRef(null);

  const [map, setMap] = useState(null);
  const [activeLayer, setActiveLayer] = useState("maxdepth");
  const [currentTime, setCurrentTime] = useState(1);
  const [availableLayers, setAvailableLayers] = useState([]);
  const [selectedDynamicLayer, setSelectedDynamicLayer] = useState(null);
  const [isLayerLoading, setIsLayerLoading] = useState(false);

  // Create map once
  useEffect(() => {
    const m = new Map({
      target: mapRef.current,
      layers: [
        new TileLayer({
          source: new OSM(),
        }),
      ],
      view: new View({
        center: [9000000, 2300000],
        zoom: 5,
      }),
    });

    setMap(m);

    return () => m.setTarget(undefined);
  }, []);

  // Helper: convert slider step -> fake WMS time
  const formatTime = (step) => {
    const padded = String(step).padStart(4, "0");
    return `${padded}-01-01T00:00:00.000Z`;
  };

  // Helper: detect if layer is timeseries or max depth
  const detectLayerType = (layerName) => {
    if (layerName.endsWith("_timeseries")) {
      return "timeseries";
    } else if (layerName.endsWith("_max_depth")) {
      return "maxdepth";
    }
    return null;
  };

  // Helper: format layer name for display
  const formatLayerName = (layerName) => {
    // Remove the suffix (_max_depth or _timeseries)
    let displayName = layerName
      .replace(/_max_depth$/, "")
      .replace(/_timeseries$/, "");
    
    // Replace underscores with spaces and capitalize words
    displayName = displayName
      .split("_")
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");
    
    return displayName;
  };

  // Helper: categorize layers
  const categorizedLayers = () => {
    const maxDepthLayers = [];
    const timeseriesLayers = [];
    
    availableLayers.forEach(layer => {
      const type = detectLayerType(layer);
      if (type === "maxdepth") {
        maxDepthLayers.push(layer);
      } else if (type === "timeseries") {
        timeseriesLayers.push(layer);
      }
    });
    
    // Sort layers alphabetically by formatted name
    maxDepthLayers.sort((a, b) => formatLayerName(a).localeCompare(formatLayerName(b)));
    timeseriesLayers.sort((a, b) => formatLayerName(a).localeCompare(formatLayerName(b)));
    
    return { maxDepthLayers, timeseriesLayers };
  };

  // Whenever layer or time changes → recreate WMS layer
  useEffect(() => {
    if (!map) return;

    setIsLayerLoading(true);

    // Remove old WMS layer
    if (wmsLayerRef.current) {
      map.removeLayer(wmsLayerRef.current);
      wmsLayerRef.current = null;
    }

    let cfg;
    if (selectedDynamicLayer) {
      // Use the dynamically selected layer
      cfg = {
        name: selectedDynamicLayer,
        bbox: geoserverConfig.maxDepthLayer.bbox,
        projection: geoserverConfig.maxDepthLayer.projection,
      };
    } else if (activeLayer === "maxdepth") {
      cfg = geoserverConfig.maxDepthLayer;
    } else {
      cfg = geoserverConfig.timeseriesLayer;
    }

    const params = {
      LAYERS: `${geoserverConfig.workspace}:${cfg.name}`,
      FORMAT: "image/png",
      TRANSPARENT: true,
    };

    // Add TIME param only for timeseries
    if (activeLayer === "timeseries") {
      params.TIME = formatTime(currentTime);
    }

    const wmsSource = new ImageWMS({
      url: `${geoserverConfig.baseUrl}/${geoserverConfig.workspace}/wms`,
      params,
      serverType: "geoserver",
      crossOrigin: "anonymous",
      projection: cfg.projection,
    });

    // Listen for image load events
    wmsSource.on('imageloadstart', () => {
      setIsLayerLoading(true);
    });

    wmsSource.on('imageloadend', () => {
      setIsLayerLoading(false);
    });

    wmsSource.on('imageloaderror', () => {
      setIsLayerLoading(false);
      console.error('Failed to load WMS layer');
    });

    const wmsLayer = new ImageLayer({
      source: wmsSource,
      opacity: 0.75,
    });

    map.addLayer(wmsLayer);
    wmsLayerRef.current = wmsLayer;

    // Fit to layer bbox
    const extent3857 = transformExtent(
      cfg.bbox,
      cfg.projection,
      "EPSG:3857"
    );
    map.getView().fit(extent3857, { padding: [40, 40, 40, 40] });
  }, [map, activeLayer, currentTime, selectedDynamicLayer]);

  useEffect(() => {
    const testFetch = async () => {
      const layers = await fetchAvailableLayers();
      console.log("Available layers:", layers);
    };
    testFetch();
  }, []);

  useEffect(() => {
    const loadLayers = async () => {
      const layers = await fetchAvailableLayers();
      console.log("Available layers:", layers);
      setAvailableLayers(layers);
    };
    loadLayers();
  }, []);

  // Handler for layer click - auto-detect type and switch mode
  const handleLayerClick = (layerName) => {
    const layerType = detectLayerType(layerName);
    
    if (layerType) {
      setActiveLayer(layerType);
      setSelectedDynamicLayer(layerName);
      setCurrentTime(1); // Reset time to 1
    } else {
      // Fallback if layer type cannot be detected
      setSelectedDynamicLayer(layerName);
    }
  };

  const { maxDepthLayers, timeseriesLayers } = categorizedLayers();

  return (
    <div style={{ width: "100%", height: "100vh", position: "relative" }}>
      <div ref={mapRef} style={{ width: "100%", height: "100%" }} />

      {/* Loading Indicator */}
      {isLayerLoading && (
        <div
          style={{
            position: "absolute",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            background: "rgba(0, 0, 0, 0.7)",
            color: "white",
            padding: "20px 30px",
            borderRadius: "8px",
            zIndex: 2000,
            display: "flex",
            alignItems: "center",
            gap: "15px",
            boxShadow: "0 4px 6px rgba(0,0,0,0.3)",
          }}
        >
          <div
            style={{
              width: "30px",
              height: "30px",
              border: "3px solid #f3f3f3",
              borderTop: "3px solid #3498db",
              borderRadius: "50%",
              animation: "spin 1s linear infinite",
            }}
          />
          <span style={{ fontSize: "16px", fontWeight: "500" }}>Loading layer...</span>
          <style>{`
            @keyframes spin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
          `}</style>
        </div>
      )}

      {/* Controls */}
      <div
        style={{
          position: "absolute",
          top: "10px",
          right: "10px",
          background: "white",
          padding: "15px",
          borderRadius: "5px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.2)",
          zIndex: 1000,
          width: "260px",
          maxHeight: "calc(100vh - 40px)",
          overflowY: "auto",
        }}
      >
        <h3 style={{ margin: "0 0 15px 0", fontSize: "16px", fontWeight: "bold" }}>
          Layer Control
        </h3>

        {activeLayer === "timeseries" && (
          <div style={{ marginBottom: "20px", padding: "10px", background: "#f5f5f5", borderRadius: "4px" }}>
            <label style={{ display: "block", marginBottom: "8px", fontWeight: "bold", fontSize: "13px" }}>
              Time Step: {currentTime} / {geoserverConfig.timeseriesLayer.timeSteps}
            </label>
            <input
              type="range"
              min="1"
              max={geoserverConfig.timeseriesLayer.timeSteps}
              value={currentTime}
              onChange={(e) => setCurrentTime(parseInt(e.target.value))}
              style={{ width: "100%" }}
            />
          </div>
        )}

        {availableLayers.length === 0 ? (
          <p style={{ fontSize: "12px", color: "#666" }}>Loading layers...</p>
        ) : (
          <>
            {/* Max Depth Layers */}
            {maxDepthLayers.length > 0 && (
              <div style={{ marginBottom: "20px" }}>
                <h4 style={{ 
                  margin: "0 0 10px 0", 
                  fontSize: "14px", 
                  fontWeight: "bold",
                  color: "#333",
                  borderBottom: "2px solid #0066cc",
                  paddingBottom: "5px"
                }}>
                  Max Depth Layers
                </h4>
                <ul style={{ margin: 0, padding: 0, listStyle: "none" }}>
                  {maxDepthLayers.map((layer) => (
                    <li
                      key={layer}
                      onClick={() => handleLayerClick(layer)}
                      style={{
                        cursor: "pointer",
                        padding: "8px 10px",
                        marginBottom: "4px",
                        background: selectedDynamicLayer === layer ? "#e6f3ff" : "#f9f9f9",
                        border: selectedDynamicLayer === layer ? "2px solid #0066cc" : "1px solid #ddd",
                        borderRadius: "4px",
                        color: selectedDynamicLayer === layer ? "#0066cc" : "#333",
                        fontWeight: selectedDynamicLayer === layer ? "bold" : "normal",
                        fontSize: "13px",
                        transition: "all 0.2s ease"
                      }}
                      onMouseEnter={(e) => {
                        if (selectedDynamicLayer !== layer) {
                          e.target.style.background = "#f0f0f0";
                        }
                      }}
                      onMouseLeave={(e) => {
                        if (selectedDynamicLayer !== layer) {
                          e.target.style.background = "#f9f9f9";
                        }
                      }}
                    >
                      {formatLayerName(layer)}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Timeseries Layers */}
            {timeseriesLayers.length > 0 && (
              <div>
                <h4 style={{ 
                  margin: "0 0 10px 0", 
                  fontSize: "14px", 
                  fontWeight: "bold",
                  color: "#333",
                  borderBottom: "2px solid #009900",
                  paddingBottom: "5px"
                }}>
                  Time Series Layers
                </h4>
                <ul style={{ margin: 0, padding: 0, listStyle: "none" }}>
                  {timeseriesLayers.map((layer) => (
                    <li
                      key={layer}
                      onClick={() => handleLayerClick(layer)}
                      style={{
                        cursor: "pointer",
                        padding: "8px 10px",
                        marginBottom: "4px",
                        background: selectedDynamicLayer === layer ? "#e6ffe6" : "#f9f9f9",
                        border: selectedDynamicLayer === layer ? "2px solid #009900" : "1px solid #ddd",
                        borderRadius: "4px",
                        color: selectedDynamicLayer === layer ? "#009900" : "#333",
                        fontWeight: selectedDynamicLayer === layer ? "bold" : "normal",
                        fontSize: "13px",
                        transition: "all 0.2s ease"
                      }}
                      onMouseEnter={(e) => {
                        if (selectedDynamicLayer !== layer) {
                          e.target.style.background = "#f0f0f0";
                        }
                      }}
                      onMouseLeave={(e) => {
                        if (selectedDynamicLayer !== layer) {
                          e.target.style.background = "#f9f9f9";
                        }
                      }}
                    >
                      {formatLayerName(layer)}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </>
        )}
      </div>

      {/* Legend */}
      <div
        style={{
          position: "absolute",
          bottom: "20px",
          left: "10px",
          background: "white",
          padding: "15px",
          borderRadius: "5px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.2)",
          zIndex: 1000,
          width: "200px",
        }}
      >
        <h4 style={{ margin: "0 0 10px 0", fontSize: "14px", fontWeight: "bold" }}>
          Flood Depth Legend
        </h4>
        <div style={{ fontSize: "12px" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ffff00", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>0.01m - Very Low</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ffcc00", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>0.2m - Low</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ff9900", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>0.5m - Moderate</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ff6600", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>1m - High</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ff3300", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>2m - Very High</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#ff0000", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>3.5m - Severe</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#cc0000", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>5m - Extreme</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", marginBottom: "4px" }}>
            <div style={{ width: "30px", height: "15px", background: "#990000", marginRight: "8px", border: "1px solid #ccc" }}></div>
            <span>10m - Catastrophic</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MapComponent;