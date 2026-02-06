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

  // Whenever layer or time changes → recreate WMS layer
  useEffect(() => {
    if (!map) return;

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

    const wmsLayer = new ImageLayer({
      source: new ImageWMS({
        url: `${geoserverConfig.baseUrl}/${geoserverConfig.workspace}/wms`,
        params,
        serverType: "geoserver",
        crossOrigin: "anonymous",
        projection: cfg.projection,
      }),
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

  return (
    <div style={{ width: "100%", height: "100vh", position: "relative" }}>
      <div ref={mapRef} style={{ width: "100%", height: "100%" }} />

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
          width: "240px",
        }}
      >
        <h3 style={{ margin: "0 0 10px 0" }}>Layer Control</h3>

        <div style={{ marginBottom: "15px" }}>
          <label style={{ display: "block", marginBottom: "5px", cursor: "pointer" }}>
            <input
              type="radio"
              value="maxdepth"
              checked={activeLayer === "maxdepth"}
              onChange={(e) => {
                setActiveLayer(e.target.value);
                setCurrentTime(1);
              }}
            />
            {" "}Max Depth
          </label>

          <label style={{ display: "block", cursor: "pointer" }}>
            <input
              type="radio"
              value="timeseries"
              checked={activeLayer === "timeseries"}
              onChange={(e) => {
                setActiveLayer(e.target.value);
                setCurrentTime(1);
              }}
            />
            {" "}Time Series
          </label>
        </div>

        {activeLayer === "timeseries" && (
          <div>
            <label style={{ display: "block", marginBottom: "5px", fontWeight: "bold" }}>
              Time Step: {currentTime} / {geoserverConfig.timeseriesLayer.timeSteps}
            </label>
            <input
              type="range"
              min="1"
              max={geoserverConfig.timeseriesLayer.timeSteps}
              value={currentTime}
              onChange={(e) => setCurrentTime(parseInt(e.target.value))}
              style={{ width: "200px" }}
            />
          </div>
        )}

        <div style={{ marginTop: "20px", borderTop: "1px solid #ccc", paddingTop: "15px" }}>
          <h4 style={{ margin: "0 0 10px 0" }}>Available Layers</h4>
          {availableLayers.length === 0 ? (
            <p style={{ fontSize: "12px", color: "#666" }}>Loading...</p>
          ) : (
            <ul style={{ margin: 0, padding: "0 0 0 20px", fontSize: "13px" }}>
              {availableLayers.map((layer) => (
                <li
                  key={layer}
                  onClick={() => setSelectedDynamicLayer(layer)}
                  style={{
                    cursor: "pointer",
                    padding: "3px 0",
                    color: selectedDynamicLayer === layer ? "#009900" : "#0066cc",
                    fontWeight: selectedDynamicLayer === layer ? "bold" : "normal"
                  }}
                >
                  {layer}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>


    </div>
  );
};

export default MapComponent;