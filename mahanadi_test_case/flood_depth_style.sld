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

              <ColorMapEntry color="#ffff00" quantity="0.01" opacity="0.9" label="Very Low"/>
              <ColorMapEntry color="#ffcc00" quantity="0.2" opacity="0.95" label="Low"/>
              <ColorMapEntry color="#ff9900" quantity="0.5" opacity="0.95" label="Moderate"/>
              <ColorMapEntry color="#ff6600" quantity="1" opacity="1.0" label="High"/>
              <ColorMapEntry color="#ff3300" quantity="2" opacity="1.0" label="Very High"/>
              <ColorMapEntry color="#ff0000" quantity="3.5" opacity="1.0" label="Severe"/>
              <ColorMapEntry color="#cc0000" quantity="5" opacity="1.0" label="Extreme"/>
              <ColorMapEntry color="#990000" quantity="10" opacity="1.0" label="Catastrophic"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>