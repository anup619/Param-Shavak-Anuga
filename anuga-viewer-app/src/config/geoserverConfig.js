export const geoserverConfig = {
  baseUrl: "/geoserver",
  workspace: "anuga",

  maxDepthLayer: {
    name: "mahanadi_dam_release_max_depth",
    title: "Max Depth",
    bbox: [392635.0, 2248090.0, 417935.0, 2263390.0],
    projection: "EPSG:32645",
  },

  timeseriesLayer: {
    name: "timeseries",
    title: "Time Series",
    bbox: [392635.0, 2248090.0, 417935.0, 2263390.0],
    projection: "EPSG:32645",
    startTime: "0001-01-01T00:00:00.000Z",
    timeSteps: 25,
  },
  indiaExtent: [7600000, 800000, 10800000, 3700000],
};
