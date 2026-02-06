<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <Name>Flood Depth</Name>
    <UserStyle>
      <Name>flood_depth_interpolated</Name>
      <Title>Flood Depth (Interpolated)</Title>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <ColorMap type="ramp">
              <ColorMapEntry color="#000000" quantity="-9999" opacity="0" label="No Data"/>
              <ColorMapEntry color="#ffffff" quantity="0" opacity="0" label="No Flood"/>
              <ColorMapEntry color="#d4f1f9" quantity="0.01" opacity="0.8" label="0.01m"/>
              <ColorMapEntry color="#73b2ff" quantity="0.5" opacity="0.85" label="0.5m"/>
              <ColorMapEntry color="#0070ff" quantity="1" opacity="0.9" label="1m"/>
              <ColorMapEntry color="#ffff00" quantity="2" opacity="0.9" label="2m"/>
              <ColorMapEntry color="#ffaa00" quantity="3.5" opacity="0.95" label="3.5m"/>
              <ColorMapEntry color="#ff5500" quantity="5" opacity="0.95" label="5m"/>
              <ColorMapEntry color="#ff0000" quantity="10" opacity="1.0" label="10m+"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>